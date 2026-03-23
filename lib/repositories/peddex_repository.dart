import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:peddex/repositories/generic_repository.dart';
import 'package:peddex/utils/ownership_helper.dart';

typedef PeddexFromJson<T> = T Function(Map<String, dynamic> json);
typedef PeddexToJson<T> = Map<String, dynamic> Function(T entity);

/// Generic Firestore repository for flat, owned collections.
///
/// Guarantees:
/// - ownership fields (`ownerId`, `kennelId`) injected on every write
/// - active-record reads include `isDeleted == false` by default
class PeddexRepository<T> {
  static int _firestoreReadCount = 0;
  static final Map<String, int> _cacheEntriesByRepo = <String, int>{};

  final String collection;
  final PeddexFromJson<T> fromJson;
  final PeddexToJson<T> toJson;
  final FirebaseFirestore _firestore;
  final Map<String, List<T>> _cache = <String, List<T>>{};
  final Set<String> _refreshInFlight = <String>{};
  final String _repoMetricsKey;

  PeddexRepository({
    required this.collection,
    required this.fromJson,
    required this.toJson,
    FirebaseFirestore? firestore,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _repoMetricsKey = '${collection}_${identityHashCode(Object())}';

  static int get firestoreReadCount => _firestoreReadCount;

  static int get activeCacheEntries => _cacheEntriesByRepo.values.fold<int>(
        0,
        (sum, entries) => sum + entries,
      );

  void _registerCacheEntryCount() {
    _cacheEntriesByRepo[_repoMetricsKey] = _cache.length;
  }

  void _clearCacheAndMetrics() {
    _cache.clear();
    _registerCacheEntryCount();
  }

  String _cacheKey(String userId, bool includeDeleted, int? limit) {
    return '$userId|$includeDeleted|${limit ?? 'all'}';
  }

  Query<Map<String, dynamic>> baseQuery(
    String userId, {
    bool includeDeleted = false,
    int? limit,
  }) {
    final ownership = OwnershipHelper.fieldsForUser(userId);
    final kennelId = ownership['kennelId'] as String?;
    Query<Map<String, dynamic>> query = _firestore.collection(collection);

    if (kennelId != null && kennelId.isNotEmpty) {
      query = query.where('kennelId', isEqualTo: kennelId);
    } else {
      query = query
          .where('ownerId', isEqualTo: userId)
          .where('kennelId', isNull: true);
    }

    if (!includeDeleted) {
      query = query.where('isDeleted', isEqualTo: false);
    }
    if (limit != null && limit > 0) {
      query = query.limit(limit);
    }
    return query;
  }

  Future<List<T>> _refreshGetAll(
    String userId, {
    required bool includeDeleted,
    int? limit,
  }) async {
    final snap = await baseQuery(
      userId,
      includeDeleted: includeDeleted,
      limit: limit,
    ).get();
    if (!snap.metadata.isFromCache) {
      _firestoreReadCount++;
    }
    final data = snap.docs.map((d) => fromJson(d.data())).toList();
    _cache[_cacheKey(userId, includeDeleted, limit)] = data;
    _registerCacheEntryCount();
    return data;
  }

  Future<List<T>> getAll(
    String userId, {
    bool includeDeleted = false,
    int? limit,
  }) async {
    final key = _cacheKey(userId, includeDeleted, limit);
    final cached = _cache[key];
    if (cached != null) {
      // SWR: return stale data now, refresh in background.
      if (!_refreshInFlight.contains(key)) {
        _refreshInFlight.add(key);
        unawaited(
          _refreshGetAll(
            userId,
            includeDeleted: includeDeleted,
            limit: limit,
          ).whenComplete(() => _refreshInFlight.remove(key)),
        );
      }
      return cached;
    }

    return _refreshGetAll(
      userId,
      includeDeleted: includeDeleted,
      limit: limit,
    );
  }

  Stream<List<T>> streamAll(
    String userId, {
    bool includeDeleted = false,
    int? limit,
  }) async* {
    final key = _cacheKey(userId, includeDeleted, limit);
    final cached = _cache[key];
    if (cached != null) {
      yield cached;
    }

    yield* baseQuery(
      userId,
      includeDeleted: includeDeleted,
      limit: limit,
    ).snapshots().map((snap) {
      if (!snap.metadata.isFromCache) {
        _firestoreReadCount++;
      }
      final data = snap.docs.map((d) => fromJson(d.data())).toList();
      _cache[key] = data;
      _registerCacheEntryCount();
      return data;
    });
  }

  Future<RepositoryWriteResult> save(
    String userId,
    String id,
    T entity,
  ) async {
    return saveMap(userId, id, toJson(entity));
  }

  Future<RepositoryWriteResult> saveMap(
    String userId,
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final payload = OwnershipHelper.mergeWithOwnership(
        userId: userId,
        data: {
          ...data,
          'id': id,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );
      await _firestore
          .collection(collection)
          .doc(id)
          .set(payload, SetOptions(merge: true));
      _clearCacheAndMetrics();
      return RepositoryWriteResult.success();
    } on FirebaseException catch (e) {
      return RepositoryWriteResult.failure(
        errorCode: e.code,
        message: e.message ?? 'Failed writing $collection/$id',
        error: e,
      );
    } catch (e) {
      return RepositoryWriteResult.failure(
        message: 'Failed writing $collection/$id',
        error: e,
      );
    }
  }

  Future<RepositoryWriteResult> softDelete(String userId, String id) async {
    try {
      await _firestore.collection(collection).doc(id).update({
        'isDeleted': true,
        'deletedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _clearCacheAndMetrics();
      return RepositoryWriteResult.success();
    } on FirebaseException catch (_) {
      return saveMap(userId, id, {
        'isDeleted': true,
        'deletedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      return RepositoryWriteResult.failure(
        message: 'Failed soft-deleting $collection/$id',
        error: e,
      );
    }
  }

  Future<RepositoryWriteResult> hardDelete(String id) async {
    try {
      await _firestore.collection(collection).doc(id).delete();
      _clearCacheAndMetrics();
      return RepositoryWriteResult.success();
    } on FirebaseException catch (e) {
      return RepositoryWriteResult.failure(
        errorCode: e.code,
        message: e.message ?? 'Failed deleting $collection/$id',
        error: e,
      );
    } catch (e) {
      return RepositoryWriteResult.failure(
        message: 'Failed deleting $collection/$id',
        error: e,
      );
    }
  }
}
