import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:breedly/models/feed_post.dart';
import 'package:breedly/services/auth_service.dart';

import 'package:breedly/utils/logger.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Service for managing the Breedly social feed.
///
/// Firestore structure:
///   public_feed/{postId}        — All feed posts
///   kennel_followers/{kennelId} — Follower lists
///   user_following/{userId}     — Who a user follows
///   kennel_profiles_public/{kennelId} — Public kennel profiles
class FeedService {
  static final FeedService _instance = FeedService._internal();
  factory FeedService() => _instance;
  FeedService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Local cache
  List<FeedPost> _cachedFeed = [];
  DateTime? _lastFetchTime;
  static const _cacheDuration = Duration(minutes: 5);

  // ─────────────────────────────────────────────
  // Public kennel profile management
  // ─────────────────────────────────────────────

  /// Make a kennel profile public (opt-in)
  Future<void> publishKennelProfile({
    required String kennelId,
    required String kennelName,
    required List<String> breeds,
    String? description,
    String? region,
  }) async {
    try {
      await _firestore.collection('kennel_profiles_public').doc(kennelId).set({
        'kennelId': kennelId,
        'kennelName': kennelName,
        'breeds': breeds,
        'description': description,
        'region': region,
        'ownerId': AuthService().currentUserId,
        'followerCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isActive': true,
      }, SetOptions(merge: true));
      AppLogger.info('Published kennel profile: $kennelName');
    } catch (e) {
      AppLogger.error('Failed to publish kennel profile', e);
    }
  }

  /// Remove kennel from public (opt-out)
  Future<void> unpublishKennelProfile(String kennelId) async {
    try {
      await _firestore
          .collection('kennel_profiles_public')
          .doc(kennelId)
          .update({'isActive': false});
    } catch (e) {
      AppLogger.error('Failed to unpublish kennel profile', e);
    }
  }

  /// Search public kennels by breed
  Future<List<Map<String, dynamic>>> searchKennelsByBreed(String breed) async {
    try {
      final snapshot = await _firestore
          .collection('kennel_profiles_public')
          .where('breeds', arrayContains: breed)
          .where('isActive', isEqualTo: true)
          .orderBy('kennelName')
          .limit(50)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      AppLogger.error('Failed to search kennels', e);
      return [];
    }
  }

  /// Search public kennels by name
  Future<List<Map<String, dynamic>>> searchKennelsByName(String name) async {
    try {
      final normalizedName = name.toLowerCase().trim();
      final snapshot = await _firestore
          .collection('kennel_profiles_public')
          .where('isActive', isEqualTo: true)
          .orderBy('kennelName')
          .startAt([normalizedName])
          .endAt(['$normalizedName\uf8ff'])
          .limit(20)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      AppLogger.error('Failed to search kennels by name', e);
      return [];
    }
  }

  // ─────────────────────────────────────────────
  // Follow / unfollow
  // ─────────────────────────────────────────────

  /// Follow a kennel
  Future<void> followKennel(String kennelId) async {
    final userId = AuthService().currentUserId;
    if (userId == null) return;

    try {
      final batch = _firestore.batch();

      // Add to user's following list
      batch.set(
        _firestore.collection('user_following').doc(userId),
        {
          'following': FieldValue.arrayUnion([kennelId]),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      // Add user to kennel's followers
      batch.set(
        _firestore.collection('kennel_followers').doc(kennelId),
        {
          'followers': FieldValue.arrayUnion([userId]),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      // Increment follower count on public profile
      batch.update(
        _firestore.collection('kennel_profiles_public').doc(kennelId),
        {'followerCount': FieldValue.increment(1)},
      );

      await batch.commit();
      AppLogger.info('Followed kennel: $kennelId');
    } catch (e) {
      AppLogger.error('Failed to follow kennel', e);
    }
  }

  /// Unfollow a kennel
  Future<void> unfollowKennel(String kennelId) async {
    final userId = AuthService().currentUserId;
    if (userId == null) return;

    try {
      final batch = _firestore.batch();

      batch.set(
        _firestore.collection('user_following').doc(userId),
        {
          'following': FieldValue.arrayRemove([kennelId]),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      batch.set(
        _firestore.collection('kennel_followers').doc(kennelId),
        {
          'followers': FieldValue.arrayRemove([userId]),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      batch.update(
        _firestore.collection('kennel_profiles_public').doc(kennelId),
        {'followerCount': FieldValue.increment(-1)},
      );

      await batch.commit();
    } catch (e) {
      AppLogger.error('Failed to unfollow kennel', e);
    }
  }

  /// Get list of kennel IDs user is following
  Future<List<String>> getFollowing() async {
    final userId = AuthService().currentUserId;
    if (userId == null) return [];

    try {
      final doc = await _firestore
          .collection('user_following')
          .doc(userId)
          .get();

      if (!doc.exists) return [];
      final data = doc.data();
      if (data == null) return [];

      final following = data['following'];
      if (following is List) {
        return following.cast<String>();
      }
      return [];
    } catch (e) {
      AppLogger.error('Failed to get following list', e);
      return [];
    }
  }

  /// Check if user follows a given kennel
  Future<bool> isFollowing(String kennelId) async {
    final following = await getFollowing();
    return following.contains(kennelId);
  }

  // ─────────────────────────────────────────────
  // Publishing feed posts
  // ─────────────────────────────────────────────

  /// Publish a post to the public feed
  Future<void> publishPost(FeedPost post) async {
    try {
      await _firestore.collection('public_feed').doc(post.id).set(post.toJson());

      // Also cache locally
      try {
        final box = Hive.box<FeedPost>('feed_posts');
        await box.put(post.id, post);
      } catch (_) {}

      _cachedFeed.insert(0, post);
      AppLogger.info('Published feed post: ${post.title}');
    } catch (e) {
      AppLogger.error('Failed to publish feed post', e);
      rethrow;
    }
  }

  /// Delete a post (only own posts)
  Future<void> deletePost(String postId) async {
    try {
      await _firestore.collection('public_feed').doc(postId).delete();
      _cachedFeed.removeWhere((p) => p.id == postId);

      try {
        final box = Hive.box<FeedPost>('feed_posts');
        await box.delete(postId);
      } catch (_) {}
    } catch (e) {
      AppLogger.error('Failed to delete feed post', e);
    }
  }

  /// Like/unlike a post
  Future<void> toggleLike(String postId) async {
    final userId = AuthService().currentUserId;
    if (userId == null) return;

    try {
      final postRef = _firestore.collection('public_feed').doc(postId);
      final likesRef = postRef.collection('likes').doc(userId);
      final likeDoc = await likesRef.get();

      if (likeDoc.exists) {
        await likesRef.delete();
        await postRef.update({'likes': FieldValue.increment(-1)});
      } else {
        await likesRef.set({'userId': userId, 'timestamp': FieldValue.serverTimestamp()});
        await postRef.update({'likes': FieldValue.increment(1)});
      }
    } catch (e) {
      AppLogger.error('Failed to toggle like', e);
    }
  }

  /// Check if user has liked a post
  Future<bool> hasLiked(String postId) async {
    final userId = AuthService().currentUserId;
    if (userId == null) return false;

    try {
      final doc = await _firestore
          .collection('public_feed')
          .doc(postId)
          .collection('likes')
          .doc(userId)
          .get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // Reading feed
  // ─────────────────────────────────────────────

  /// Get feed posts for the user (from followed kennels + same breed)
  /// Returns posts sorted by timestamp (newest first)
  Future<List<FeedPost>> getFeed({
    FeedPostType? filterType,
    int limit = 30,
    DateTime? olderThan,
  }) async {
    final userId = AuthService().currentUserId;

    try {
      // Build query
      Query<Map<String, dynamic>> query = _firestore
          .collection('public_feed')
          .orderBy('timestamp', descending: true)
          .limit(limit);

      // Filter by type if specified
      if (filterType != null) {
        query = query.where('type', isEqualTo: filterType.name);
      }

      // Pagination
      if (olderThan != null) {
        query = query.where('timestamp', isLessThan: olderThan.toIso8601String());
      }

      final snapshot = await query.get();
      final following = await getFollowing();

      final posts = snapshot.docs
          .map((doc) => FeedPost.fromJson(doc.data()))
          .where((post) {
        // Filter: public posts, or followers-only from followed kennels
        if (post.visibility == 'public') return true;
        if (post.authorId == userId) return true;
        if (following.contains(post.kennelId)) return true;
        return false;
      }).toList();

      _cachedFeed = posts;
      _lastFetchTime = DateTime.now();

      // Cache locally
      _cachePostsLocally(posts);

      return posts;
    } catch (e) {
      AppLogger.error('Failed to fetch feed', e);
      // Fall back to local cache
      return _getLocalCachedPosts(filterType: filterType);
    }
  }

  /// Get feed from followed kennels only
  Future<List<FeedPost>> getFollowingFeed({
    FeedPostType? filterType,
    int limit = 30,
  }) async {
    final following = await getFollowing();
    if (following.isEmpty) return [];

    try {
      // Firestore 'in' queries support max 30 values
      final chunks = <List<String>>[];
      for (int i = 0; i < following.length; i += 30) {
        chunks.add(following.sublist(i, i + 30 > following.length ? following.length : i + 30));
      }

      final allPosts = <FeedPost>[];
      for (final chunk in chunks) {
        Query<Map<String, dynamic>> query = _firestore
            .collection('public_feed')
            .where('kennelId', whereIn: chunk)
            .orderBy('timestamp', descending: true)
            .limit(limit);

        if (filterType != null) {
          query = query.where('type', isEqualTo: filterType.name);
        }

        final snapshot = await query.get();
        allPosts.addAll(snapshot.docs.map((doc) => FeedPost.fromJson(doc.data())));
      }

      allPosts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return allPosts.take(limit).toList();
    } catch (e) {
      AppLogger.error('Failed to fetch following feed', e);
      return [];
    }
  }

  /// Get feed filtered by breed
  Future<List<FeedPost>> getBreedFeed({
    required String breed,
    FeedPostType? filterType,
    int limit = 30,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection('public_feed')
          .where('breed', isEqualTo: breed)
          .where('visibility', isEqualTo: 'public')
          .orderBy('timestamp', descending: true)
          .limit(limit);

      if (filterType != null) {
        query = query.where('type', isEqualTo: filterType.name);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => FeedPost.fromJson(doc.data())).toList();
    } catch (e) {
      AppLogger.error('Failed to fetch breed feed', e);
      return [];
    }
  }

  /// Get count of unread posts since last check
  Future<int> getUnreadCount() async {
    try {
      final box = Hive.box<FeedPost>('feed_posts');
      final lastReadTime = box.get('_last_read_time');
      final DateTime cutoff = lastReadTime?.timestamp ?? DateTime.now().subtract(const Duration(days: 7));

      final following = await getFollowing();
      if (following.isEmpty) {
        // If not following anyone, count public posts for same breed
        final kennelBox = Hive.box('kennel_profile');
        final profile = kennelBox.values.firstOrNull;
        if (profile == null) return 0;

        final snapshot = await _firestore
            .collection('public_feed')
            .where('visibility', isEqualTo: 'public')
            .where('timestamp', isGreaterThan: cutoff.toIso8601String())
            .orderBy('timestamp', descending: true)
            .limit(100)
            .get();

        return snapshot.docs.length;
      }

      // Count posts from followed kennels
      final snapshot = await _firestore
          .collection('public_feed')
          .where('timestamp', isGreaterThan: cutoff.toIso8601String())
          .orderBy('timestamp', descending: true)
          .limit(100)
          .get();

      final userId = AuthService().currentUserId;
      return snapshot.docs.where((doc) {
        final data = doc.data();
        if (data['authorId'] == userId) return false; // Skip own posts
        if (data['visibility'] == 'public') return true;
        return following.contains(data['kennelId']);
      }).length;
    } catch (e) {
      AppLogger.error('Failed to get unread count', e);
      return 0;
    }
  }

  /// Mark all posts as read
  Future<void> markAllAsRead() async {
    try {
      final box = Hive.box<FeedPost>('feed_posts');
      final marker = FeedPost(
        id: '_last_read_time',
        authorId: '',
        kennelId: '',
        kennelName: '',
        breed: '',
        type: 'marker',
        visibility: 'public',
        timestamp: DateTime.now(),
        title: '',
      );
      await box.put('_last_read_time', marker);
    } catch (e) {
      AppLogger.error('Failed to mark as read', e);
    }
  }

  /// Get cached feed (for quick display before network fetch)
  List<FeedPost> getCachedFeed() {
    if (_cachedFeed.isNotEmpty &&
        _lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!) < _cacheDuration) {
      return _cachedFeed;
    }
    return _getLocalCachedPosts();
  }

  // ─────────────────────────────────────────────
  // Private helpers
  // ─────────────────────────────────────────────

  void _cachePostsLocally(List<FeedPost> posts) {
    try {
      final box = Hive.box<FeedPost>('feed_posts');
      for (final post in posts) {
        box.put(post.id, post);
      }
    } catch (_) {}
  }

  List<FeedPost> _getLocalCachedPosts({FeedPostType? filterType}) {
    try {
      final box = Hive.box<FeedPost>('feed_posts');
      var posts = box.values
          .where((p) => p.id != '_last_read_time')
          .toList();

      if (filterType != null) {
        posts = posts.where((p) => p.postType == filterType).toList();
      }

      posts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return posts.take(30).toList();
    } catch (_) {
      return [];
    }
  }
}
