import 'package:hive/hive.dart';

part 'feed_post.g.dart';

/// Types of posts that can appear in the Breedly feed
enum FeedPostType {
  showResult,      // Utstillingsresultat
  championTitle,   // Ny championtittel
  litterAnnouncement, // Nytt kull
  puppiesAvailable,   // Valper tilgjengelig
}

/// Visibility levels for feed posts
enum FeedVisibility {
  public,        // Synlig for alle
  followersOnly, // Kun følgere
}

@HiveType(typeId: 36)
class FeedPost extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String authorId; // Firebase userId

  @HiveField(2)
  late String kennelId; // breeding_group ID

  @HiveField(3)
  late String kennelName;

  @HiveField(4)
  late String breed;

  @HiveField(5)
  late String type; // FeedPostType name

  @HiveField(6)
  late String visibility; // FeedVisibility name

  @HiveField(7)
  late DateTime timestamp;

  @HiveField(8)
  late String title; // Main title text

  @HiveField(9)
  String? subtitle; // Secondary info

  @HiveField(10)
  String? dogName;

  @HiveField(11)
  int likes = 0;

  @HiveField(12)
  Map<String, dynamic>? contentData; // Type-specific data (JSON)

  @HiveField(13)
  bool isRead = false; // For tracking unread posts locally

  FeedPost({
    required this.id,
    required this.authorId,
    required this.kennelId,
    required this.kennelName,
    required this.breed,
    required this.type,
    required this.visibility,
    required this.timestamp,
    required this.title,
    this.subtitle,
    this.dogName,
    this.likes = 0,
    this.contentData,
    this.isRead = false,
  });

  FeedPostType get postType {
    switch (type) {
      case 'showResult':
        return FeedPostType.showResult;
      case 'championTitle':
        return FeedPostType.championTitle;
      case 'litterAnnouncement':
        return FeedPostType.litterAnnouncement;
      case 'puppiesAvailable':
        return FeedPostType.puppiesAvailable;
      default:
        return FeedPostType.showResult;
    }
  }

  FeedVisibility get postVisibility {
    switch (visibility) {
      case 'followersOnly':
        return FeedVisibility.followersOnly;
      default:
        return FeedVisibility.public;
    }
  }

  /// Create a feed post from a show result
  factory FeedPost.fromShowResult({
    required String id,
    required String authorId,
    required String kennelId,
    required String kennelName,
    required String breed,
    required String dogName,
    required String showName,
    required DateTime showDate,
    required String quality,
    required String showClass,
    String? placement,
    List<String>? certificates,
    String? judge,
    String? groupResult,
    String? bisResult,
    bool hasCK = false,
    String visibility = 'public',
  }) {
    final parts = <String>[];
    parts.add(quality);
    if (hasCK) parts.add('CK');
    if (certificates != null && certificates.isNotEmpty) {
      parts.addAll(certificates);
    }
    if (placement != null && placement.isNotEmpty) {
      parts.add(placement);
    }
    if (groupResult != null && groupResult.isNotEmpty) {
      parts.add(groupResult);
    }
    if (bisResult != null && bisResult.isNotEmpty) {
      parts.add(bisResult);
    }

    return FeedPost(
      id: id,
      authorId: authorId,
      kennelId: kennelId,
      kennelName: kennelName,
      breed: breed,
      type: 'showResult',
      visibility: visibility,
      timestamp: DateTime.now(),
      title: '$dogName – $showName',
      subtitle: parts.join(', '),
      dogName: dogName,
      contentData: {
        'showName': showName,
        'showDate': showDate.toIso8601String(),
        'quality': quality,
        'showClass': showClass,
        'placement': placement,
        'certificates': certificates,
        'judge': judge,
        'groupResult': groupResult,
        'bisResult': bisResult,
        'hasCK': hasCK,
      },
    );
  }

  /// Create a feed post for a new champion title
  factory FeedPost.fromChampionTitle({
    required String id,
    required String authorId,
    required String kennelId,
    required String kennelName,
    required String breed,
    required String dogName,
    required String titleName,
    String visibility = 'public',
  }) {
    return FeedPost(
      id: id,
      authorId: authorId,
      kennelId: kennelId,
      kennelName: kennelName,
      breed: breed,
      type: 'championTitle',
      visibility: visibility,
      timestamp: DateTime.now(),
      title: '$dogName – $titleName',
      subtitle: kennelName,
      dogName: dogName,
      contentData: {
        'titleName': titleName,
      },
    );
  }

  /// Create a feed post for a new litter
  factory FeedPost.fromLitterAnnouncement({
    required String id,
    required String authorId,
    required String kennelId,
    required String kennelName,
    required String breed,
    required String damName,
    required String sireName,
    required int puppyCount,
    required int maleCount,
    required int femaleCount,
    required DateTime dateOfBirth,
    String visibility = 'public',
  }) {
    return FeedPost(
      id: id,
      authorId: authorId,
      kennelId: kennelId,
      kennelName: kennelName,
      breed: breed,
      type: 'litterAnnouncement',
      visibility: visibility,
      timestamp: DateTime.now(),
      title: '$kennelName – $breed',
      subtitle: '$puppyCount valper ($maleCount hannhunder, $femaleCount tisper)',
      dogName: damName,
      contentData: {
        'damName': damName,
        'sireName': sireName,
        'puppyCount': puppyCount,
        'maleCount': maleCount,
        'femaleCount': femaleCount,
        'dateOfBirth': dateOfBirth.toIso8601String(),
      },
    );
  }

  /// Create a feed post for puppies available
  factory FeedPost.fromPuppiesAvailable({
    required String id,
    required String authorId,
    required String kennelId,
    required String kennelName,
    required String breed,
    required int availableCount,
    required int maleCount,
    required int femaleCount,
    String visibility = 'public',
  }) {
    return FeedPost(
      id: id,
      authorId: authorId,
      kennelId: kennelId,
      kennelName: kennelName,
      breed: breed,
      type: 'puppiesAvailable',
      visibility: visibility,
      timestamp: DateTime.now(),
      title: '$kennelName – $breed',
      subtitle: '$availableCount tilgjengelig ($maleCount hannhunder, $femaleCount tisper)',
      dogName: null,
      contentData: {
        'availableCount': availableCount,
        'maleCount': maleCount,
        'femaleCount': femaleCount,
      },
    );
  }

  /// Serialize to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'authorId': authorId,
      'kennelId': kennelId,
      'kennelName': kennelName,
      'breed': breed,
      'type': type,
      'visibility': visibility,
      'timestamp': timestamp.toIso8601String(),
      'title': title,
      'subtitle': subtitle,
      'dogName': dogName,
      'likes': likes,
      'contentData': contentData,
    };
  }

  /// Deserialize from Firestore JSON
  factory FeedPost.fromJson(Map<String, dynamic> json) {
    return FeedPost(
      id: json['id'] ?? '',
      authorId: json['authorId'] ?? '',
      kennelId: json['kennelId'] ?? '',
      kennelName: json['kennelName'] ?? '',
      breed: json['breed'] ?? '',
      type: json['type'] ?? 'showResult',
      visibility: json['visibility'] ?? 'public',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      title: json['title'] ?? '',
      subtitle: json['subtitle'],
      dogName: json['dogName'],
      likes: json['likes'] ?? 0,
      contentData: json['contentData'] != null
          ? Map<String, dynamic>.from(json['contentData'])
          : null,
    );
  }
}
