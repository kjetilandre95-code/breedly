import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:breedly/models/kennel_analytics.dart';
import 'package:breedly/utils/logger.dart';
import 'package:breedly/utils/ownership_helper.dart';
import 'package:breedly/services/kennel_service.dart';
import 'package:breedly/services/feed_service.dart';
import 'package:breedly/repositories/generic_repository.dart';
import 'package:breedly/repositories/peddex_repository.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();

  factory FirestoreService() {
    return _instance;
  }

  FirestoreService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final PeddexRepository<Map<String, dynamic>> _dogsRepo =
      PeddexRepository<Map<String, dynamic>>(
        collection: 'dogs',
        fromJson: (json) => json,
        toJson: (entity) => entity,
      );
  late final PeddexRepository<Map<String, dynamic>> _littersRepo =
      PeddexRepository<Map<String, dynamic>>(
        collection: 'litters',
        fromJson: (json) => json,
        toJson: (entity) => entity,
      );
  late final PeddexRepository<Map<String, dynamic>> _buyersRepo =
      PeddexRepository<Map<String, dynamic>>(
        collection: 'buyers',
        fromJson: (json) => json,
        toJson: (entity) => entity,
      );
  late final PeddexRepository<Map<String, dynamic>> _waitlistRepo =
      PeddexRepository<Map<String, dynamic>>(
        collection: 'buyers',
        fromJson: (json) => json,
        toJson: (entity) => entity,
      );
  late final PeddexRepository<Map<String, dynamic>> _puppiesRepo =
      PeddexRepository<Map<String, dynamic>>(
        collection: 'puppies',
        fromJson: (json) => json,
        toJson: (entity) => entity,
      );
  late final PeddexRepository<Map<String, dynamic>> _healthRecordsRepo =
      PeddexRepository<Map<String, dynamic>>(
        collection: 'health_info',
        fromJson: (json) => json,
        toJson: (entity) => entity,
      );
  late final PeddexRepository<Map<String, dynamic>> _temperatureRecordsRepo =
      PeddexRepository<Map<String, dynamic>>(
        collection: 'temperature_records',
        fromJson: (json) => json,
        toJson: (entity) => entity,
      );
  static const String _repairUserIdentityUrl =
      'https://europe-west1-peddex-80eb0.cloudfunctions.net/repairUserIdentity';

  /// Returns ownership fields to inject into every top-level document.
  /// `kennelId` is set when the user has an active kennel, otherwise null
  /// (data belongs to the user's private profile).
  Map<String, dynamic> _ownershipFields(String userId) {
    final kennelId = KennelService().activeKennelId;
    return {
      'ownerId': userId,
      'kennelId': (kennelId != null && kennelId.isNotEmpty) ? kennelId : null,
      'isDeleted': false,
    };
  }

  /// Builds a tenant-safe query for active records.
  Query<Map<String, dynamic>> baseQuery(String collectionName, String userId) {
    if (collectionName == 'dogs') return _dogsRepo.baseQuery(userId);
    if (collectionName == 'litters') return _littersRepo.baseQuery(userId);
    if (collectionName == 'buyers') return _buyersRepo.baseQuery(userId);

    final kennelId = KennelService().activeKennelId;
    final col = _firestore.collection(collectionName);
    if (kennelId != null && kennelId.isNotEmpty) {
      return col
          .where('kennelId', isEqualTo: kennelId)
          .where('isDeleted', isEqualTo: false);
    }
    return col
        .where('ownerId', isEqualTo: userId)
        .where('kennelId', isNull: true)
        .where('isDeleted', isEqualTo: false);
  }

  /// Base document reference kept for collections not yet on flat root paths:
  /// buyers, expenses, income, kennel_profile, treatment_plans,
  /// delivery_checklists, *_contracts, custom_terms.
  DocumentReference _getBaseDoc(String userId) {
    if (userId.isEmpty) {
      throw Exception('UserId cannot be empty');
    }
    final kennelId = KennelService().activeKennelId;
    if (kennelId != null && kennelId.isNotEmpty) {
      return _firestore.collection('breeding_groups').doc(kennelId);
    }
    return _firestore.collection('users').doc(userId);
  }

  /// Check if using kennel-based storage
  bool get isUsingKennel => KennelService().activeKennelId != null;

  /// Generates a new Firestore document id for a collection.
  String newDocId(String collectionName) {
    return _firestore.collection(collectionName).doc().id;
  }

  Future<RepositoryWriteResult> _executeWrite(
    Future<void> Function() operation, {
    required String action,
  }) async {
    try {
      await operation();
      return RepositoryWriteResult.success();
    } on FirebaseException catch (e) {
      final failure = RepositoryWriteResult.failure(
        errorCode: e.code,
        message: e.message ?? action,
        error: e,
      );
      logError(failure);
      return failure;
    } catch (e) {
      final failure = RepositoryWriteResult.failure(
        message: action,
        error: e,
      );
      logError(failure);
      return failure;
    }
  }

  void logError(RepositoryWriteResult failure) {
    if (failure.isSuccess) return;
    final code = failure.errorCode ?? 'unknown';
    final message = failure.message ?? 'Unknown repository error';
    debugPrint('[ERROR][RepositoryWrite] code=$code message=$message');
  }

  /// Enable offline persistence
  Future<void> enableOfflinePersistence() async {
    try {
      // In cloud_firestore 5.x, offline persistence is enabled by default on mobile.
      // We just need to configure cache size.
      _firestore.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
    } catch (e) {
      // Settings can only be set before any Firestore operations.
      // If it fails, persistence is still enabled by default on mobile.
      debugPrint('Firestore settings note: $e');
    }
  }

  /// Disable network to simulate offline mode
  Future<void> disableNetwork() async {
    try {
      await _firestore.disableNetwork();
    } catch (e) {
      AppLogger.debug('Error disabling network: $e');
    }
  }

  /// Enable network
  Future<void> enableNetwork() async {
    try {
      await _firestore.enableNetwork();
    } catch (e) {
      AppLogger.debug('Error enabling network: $e');
    }
  }

  /// Save user profile to Firestore
  Future<RepositoryWriteResult> saveUserProfile({
    required String userId,
    required String email,
    required String displayName,
    String? photoUrl,
  }) async {
    return _executeWrite(() async {
      final userRef = _firestore.collection('users').doc(userId);
      await userRef.set({
        'email': email,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }, action: 'Error saving profile');
  }

  /// Get user profile
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.data();
    } catch (e) {
      throw Exception('Error fetching profile: $e');
    }
  }

  /// Save dog to Firestore (flat root collection `dogs/`)
  Future<RepositoryWriteResult> saveDog({
    required String userId,
    required String dogId,
    required Map<String, dynamic> dogData,
  }) async {
    return _dogsRepo.saveMap(userId, dogId, dogData);
  }

  /// Get all active dogs for current tenant.
  Future<List<Map<String, dynamic>>> getDogs(String userId) async {
    try {
      final querySnapshot = await _dogsRepo.baseQuery(userId).get();
      debugPrint('[FIRESTORE DEBUG] getDogs: found ${querySnapshot.docs.length} dogs (fromCache: ${querySnapshot.metadata.isFromCache})');
      return querySnapshot.docs
          .map((doc) => doc.data())
          .toList();
    } catch (e) {
      debugPrint('[FIRESTORE DEBUG] getDogs ERROR: $e');
      throw Exception('Error fetching dogs: $e');
    }
  }

  /// Save litter to Firestore (flat root collection `litters/`)
  Future<RepositoryWriteResult> saveLitter({
    required String userId,
    required String litterId,
    required Map<String, dynamic> litterData,
  }) async {
    return _executeWrite(() async {
      final saveResult = await _littersRepo.saveMap(userId, litterId, litterData);
      if (!saveResult.isSuccess) {
        throw Exception(saveResult.message ?? 'Error saving litter');
      }
      // Auto-publish to feed if sharing is enabled and litter is born
      final dateOfBirth = litterData['dateOfBirth'];
      final isPlanned = litterData['isPlanned'] ?? false;

      if (!isPlanned && dateOfBirth != null) {
        final parsedDateOfBirth = dateOfBirth is String
            ? DateTime.tryParse(dateOfBirth)
            : null;
        if (parsedDateOfBirth == null) {
          return;
        }
        final feedService = FeedService();
        await feedService.publishLitterToFeed(
          litterId: litterId,
          breed: litterData['breed'] ?? 'Ukjent',
          damName: litterData['damName'] ?? 'Ukjent',
          sireName: litterData['sireName'] ?? 'Ukjent',
          dateOfBirth: parsedDateOfBirth,
          puppyCount: litterData['puppyCount'] ?? 0,
          kennelId: OwnershipHelper.fieldsForUser(userId)['kennelId'] as String?,
        );
      }
    }, action: 'Error saving litter');
  }

  /// Get all active litters for current tenant.
  Future<List<Map<String, dynamic>>> getLitters(String userId) async {
    try {
      final querySnapshot = await _littersRepo.baseQuery(userId).get();
      debugPrint('[FIRESTORE DEBUG] getLitters: found ${querySnapshot.docs.length} litters (fromCache: ${querySnapshot.metadata.isFromCache})');
      return querySnapshot.docs
          .map((doc) => doc.data())
          .toList();
    } catch (e) {
      debugPrint('[FIRESTORE DEBUG] getLitters ERROR: $e');
      throw Exception('Error fetching litters: $e');
    }
  }

  /// Save puppy to Firestore (flat root collection `puppies/`)
  Future<RepositoryWriteResult> savePuppy({
    required String userId,
    required String litterId,
    required String puppyId,
    required Map<String, dynamic> puppyData,
  }) async {
    return _puppiesRepo.saveMap(
      userId,
      puppyId,
      {
        ...puppyData,
        'litterId': litterId,
      },
    );
  }

  /// Get all puppies for a litter
  Future<List<Map<String, dynamic>>> getPuppies({
    required String userId,
    required String litterId,
  }) async {
    try {
      final querySnapshot = await _puppiesRepo.baseQuery(userId)
          .where('litterId', isEqualTo: litterId)
          .get();
      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Error fetching puppies: $e');
    }
  }

  /// Save income to Firestore (flat root collection `income/`)
  Future<RepositoryWriteResult> saveIncome({
    required String userId,
    required String incomeId,
    required Map<String, dynamic> incomeData,
  }) async {
    return _executeWrite(() async {
      final data = {
        ...incomeData,
        ..._ownershipFields(userId),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      await _firestore
          .collection('income')
          .doc(incomeId)
          .set(data, SetOptions(merge: true));
    }, action: 'Error saving income');
  }

  /// Get all income for user (excludes soft-deleted)
  Future<List<Map<String, dynamic>>> getIncome(String userId) async {
    try {
      final querySnapshot = await baseQuery('income', userId)
          .orderBy('date', descending: true)
          .get();
      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Error fetching income records: $e');
    }
  }

  /// Save expense to Firestore (flat root collection `expenses/`)
  Future<RepositoryWriteResult> saveExpense({
    required String userId,
    required String expenseId,
    required Map<String, dynamic> expenseData,
  }) async {
    return _executeWrite(() async {
      final data = {
        ...expenseData,
        ..._ownershipFields(userId),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      await _firestore
          .collection('expenses')
          .doc(expenseId)
          .set(data, SetOptions(merge: true));
    }, action: 'Error saving expense');
  }

  /// Get all expenses for user (excludes soft-deleted)
  Future<List<Map<String, dynamic>>> getExpenses(String userId) async {
    try {
      final querySnapshot = await baseQuery('expenses', userId)
          .orderBy('date', descending: true)
          .get();
      return querySnapshot.docs
          .map((doc) => doc.data())
          .where((d) => d['isDeleted'] != true)
          .toList();
    } catch (e) {
      throw Exception('Error fetching expenses: $e');
    }
  }

  /// Save health info to Firestore (flat root collection `health_info/`)
  Future<RepositoryWriteResult> saveHealthInfo({
    required String userId,
    required String dogId,
    required String healthInfoId,
    required Map<String, dynamic> healthInfoData,
  }) async {
    return _healthRecordsRepo.saveMap(userId, healthInfoId, healthInfoData);
  }

  /// Get all health info for a dog
  Future<List<Map<String, dynamic>>> getHealthInfo({
    required String userId,
    required String dogId,
  }) async {
    try {
      final querySnapshot = await _healthRecordsRepo.baseQuery(userId)
          .where('dogId', isEqualTo: dogId)
          .get();
      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Error fetching health info: $e');
    }
  }

  /// Get all health info across all dogs for this user/kennel
  Future<List<Map<String, dynamic>>> getAllHealthInfo(String userId) async {
    try {
      final querySnapshot = await _healthRecordsRepo.baseQuery(userId).get();
      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Error fetching all health info: $e');
    }
  }

  /// Save vaccine to Firestore (flat root collection `vaccines/`)
  Future<RepositoryWriteResult> saveVaccine({
    required String userId,
    required String dogId,
    required String vaccineId,
    required Map<String, dynamic> vaccineData,
  }) async {
    return _executeWrite(() async {
      final data = {
        ...vaccineData,
        ..._ownershipFields(userId),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      await _firestore
          .collection('vaccines')
          .doc(vaccineId)
          .set(data, SetOptions(merge: true));
    }, action: 'Error saving vaccine');
  }

  /// Get all vaccines for a dog
  Future<List<Map<String, dynamic>>> getVaccines({
    required String userId,
    required String dogId,
  }) async {
    try {
      final querySnapshot = await baseQuery('vaccines', userId)
          .where('dogId', isEqualTo: dogId)
          .get();
      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Error fetching vaccines: $e');
    }
  }

  /// Get all vaccines across all dogs for this user/kennel
  Future<List<Map<String, dynamic>>> getAllVaccines(String userId) async {
    try {
      final querySnapshot = await baseQuery('vaccines', userId).get();
      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Error fetching all vaccines: $e');
    }
  }

  /// Delete dog
  /// Soft-delete a dog (sets isDeleted=true, deletedAt+updatedAt=now).
  /// Use [hardDeleteDog] for permanent removal.
  Future<RepositoryWriteResult> deleteDog({
    required String userId,
    required String dogId,
  }) async {
    return _dogsRepo.softDelete(userId, dogId);
  }

  /// Permanently remove a dog document from Firestore.
  Future<RepositoryWriteResult> hardDeleteDog({
    required String userId,
    required String dogId,
  }) async {
    return _dogsRepo.hardDelete(dogId);
  }

  /// Soft-delete a litter (sets isDeleted=true, deletedAt+updatedAt=now).
  Future<RepositoryWriteResult> deleteLitter({
    required String userId,
    required String litterId,
  }) async {
    return _littersRepo.softDelete(userId, litterId);
  }

  /// Permanently remove a litter document from Firestore.
  Future<RepositoryWriteResult> hardDeleteLitter({
    required String userId,
    required String litterId,
  }) async {
    return _littersRepo.hardDelete(litterId);
  }

  /// Mark a puppy as deleted (isDeleted=true).
  Future<RepositoryWriteResult> deletePuppy({
    required String userId,
    required String litterId,
    required String puppyId,
  }) async {
    return _executeWrite(() async {
      await _firestore.collection('puppies').doc(puppyId).update({
        'isDeleted': true,
        'deletedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }, action: 'Error soft-deleting puppy').then((result) async {
      if (result.isSuccess) {
        return result;
      }
      // If the document doesn't exist yet, set it with deletion markers so
      // the tombstone is preserved.
      return _executeWrite(() async {
        await _firestore.collection('puppies').doc(puppyId).set({
          'id': puppyId,
          'litterId': litterId,
          ..._ownershipFields(userId),
          'isDeleted': true,
          'deletedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }, action: 'Error soft-deleting puppy');
    });
  }

  /// Soft-delete an expense.
  Future<RepositoryWriteResult> deleteExpense({
    required String userId,
    required String expenseId,
  }) async {
    return _executeWrite(() async {
      await _firestore.collection('expenses').doc(expenseId).update({
        'isDeleted': true,
        'deletedAt': DateTime.now().toIso8601String(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }, action: 'Error soft-deleting expense');
  }

  /// Permanently remove an expense.
  Future<RepositoryWriteResult> hardDeleteExpense({
    required String userId,
    required String expenseId,
  }) async {
    return _executeWrite(() async {
      await _firestore.collection('expenses').doc(expenseId).delete();
    }, action: 'Error deleting expense');
  }

  /// Soft-delete an income record.
  Future<RepositoryWriteResult> deleteIncome({
    required String userId,
    required String incomeId,
  }) async {
    return _executeWrite(() async {
      await _firestore.collection('income').doc(incomeId).update({
        'isDeleted': true,
        'deletedAt': DateTime.now().toIso8601String(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }, action: 'Error soft-deleting income');
  }

  /// Permanently remove an income record.
  Future<RepositoryWriteResult> hardDeleteIncome({
    required String userId,
    required String incomeId,
  }) async {
    return _executeWrite(() async {
      await _firestore.collection('income').doc(incomeId).delete();
    }, action: 'Error deleting income');
  }

  /// Delete health info
  Future<RepositoryWriteResult> deleteHealthInfo({
    required String userId,
    required String dogId,
    required String healthInfoId,
  }) async {
    return _executeWrite(() async {
      await _firestore.collection('health_info').doc(healthInfoId).delete();
    }, action: 'Error deleting health info');
  }

  /// Delete vaccine
  Future<RepositoryWriteResult> deleteVaccine({
    required String userId,
    required String dogId,
    required String vaccineId,
  }) async {
    return _executeWrite(() async {
      await _firestore.collection('vaccines').doc(vaccineId).delete();
    }, action: 'Error deleting vaccine');
  }

  // ============ KENNEL PROFILE ============

  /// Save kennel settings to Firestore (flat root collection `kennel_settings/`)
  Future<RepositoryWriteResult> saveKennelProfile({
    required String userId,
    required Map<String, dynamic> profileData,
  }) async {
    return _executeWrite(() async {
      final docId = KennelService().activeKennelId ?? userId;
      final data = {
        ...profileData,
        ..._ownershipFields(userId),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      await _firestore
          .collection('kennel_settings')
          .doc(docId)
          .set(data, SetOptions(merge: true));
    }, action: 'Error saving kennel profile');
  }

  /// Get kennel settings from Firestore
  Future<Map<String, dynamic>?> getKennelProfile(String userId) async {
    try {
      final docId = KennelService().activeKennelId ?? userId;
      final doc = await _firestore
          .collection('kennel_settings')
          .doc(docId)
          .get();
      return doc.data();
    } catch (e) {
      throw Exception('Error fetching kennel profile: $e');
    }
  }

  // ============ BUYERS ============

  /// Save buyer to Firestore (flat root collection `buyers/`)
  Future<RepositoryWriteResult> saveBuyer({
    required String userId,
    required String buyerId,
    required Map<String, dynamic> buyerData,
  }) async {
    return _buyersRepo.saveMap(userId, buyerId, buyerData);
  }

  /// Get all active buyers for current tenant.
  Future<List<Map<String, dynamic>>> getBuyers(String userId) async {
    try {
      final querySnapshot = await _buyersRepo.baseQuery(userId).get();
      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Error fetching buyers: $e');
    }
  }

  /// Mark a buyer as deleted (isDeleted=true).
  Future<RepositoryWriteResult> deleteBuyer({
    required String userId,
    required String buyerId,
  }) async {
    return _buyersRepo.softDelete(userId, buyerId);
  }

  // ============ MATINGS ============

  /// Save mating to Firestore (flat root collection `matings/`)
  Future<RepositoryWriteResult> saveMating({
    required String userId,
    required String dogId,
    required String matingId,
    required Map<String, dynamic> matingData,
  }) async {
    return _executeWrite(() async {
      final data = {
        ...matingData,
        ..._ownershipFields(userId),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      await _firestore
          .collection('matings')
          .doc(matingId)
          .set(data, SetOptions(merge: true));
    }, action: 'Error saving mating');
  }

  /// Get all matings for a dog
  Future<List<Map<String, dynamic>>> getMatings({
    required String userId,
    required String dogId,
  }) async {
    try {
      final querySnapshot = await baseQuery('matings', userId)
          .where('sireId', isEqualTo: dogId)
          .get();
      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Error fetching matings: $e');
    }
  }

  /// Delete mating
  Future<RepositoryWriteResult> deleteMating({
    required String userId,
    required String dogId,
    required String matingId,
  }) async {
    return _executeWrite(() async {
      await _firestore.collection('matings').doc(matingId).delete();
    }, action: 'Error deleting mating');
  }

  // ============ TEMPERATURE RECORDS ============

  /// Save temperature record to Firestore (flat root collection `temperature_records/`)
  Future<RepositoryWriteResult> saveTemperatureRecord({
    required String userId,
    required String litterId,
    required String recordId,
    required Map<String, dynamic> recordData,
  }) async {
    return _temperatureRecordsRepo.saveMap(
      userId,
      recordId,
      {
        ...recordData,
        'litterId': litterId,
      },
    );
  }

  /// Get all temperature records for a litter
  Future<List<Map<String, dynamic>>> getTemperatureRecords({
    required String userId,
    required String litterId,
  }) async {
    try {
      final querySnapshot = await _temperatureRecordsRepo
          .baseQuery(userId)
          .where('litterId', isEqualTo: litterId)
          .orderBy('dateTime', descending: true)
          .get();
      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Error fetching temperature records: $e');
    }
  }

  /// Delete temperature record
  Future<RepositoryWriteResult> deleteTemperatureRecord({
    required String userId,
    required String litterId,
    required String recordId,
  }) async {
    return _temperatureRecordsRepo.softDelete(userId, recordId);
  }

  Stream<List<Map<String, dynamic>>> temperatureRecordsStream({
    required String userId,
    required String litterId,
    int limit = 50,
  }) {
    return _temperatureRecordsRepo
        .baseQuery(userId, limit: limit)
        .where('litterId', isEqualTo: litterId)
        .orderBy('dateTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Future<List<Map<String, dynamic>>> getTemperatureRecordsPage({
    required String userId,
    required String litterId,
    required int limit,
  }) async {
    final snap = await _temperatureRecordsRepo
        .baseQuery(userId)
        .where('litterId', isEqualTo: litterId)
        .orderBy('dateTime', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map((doc) => doc.data()).toList();
  }

  Stream<List<Map<String, dynamic>>> healthRecordsStream({
    required String userId,
    required String dogId,
    int limit = 50,
  }) {
    return _healthRecordsRepo
        .baseQuery(userId, limit: limit)
        .where('dogId', isEqualTo: dogId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Future<RepositoryWriteResult> updateLitterCounts({
    required String userId,
    required String litterId,
    required int actualMalesCount,
    required int actualFemalesCount,
  }) async {
    return _littersRepo.saveMap(userId, litterId, {
      'actualMalesCount': actualMalesCount,
      'actualFemalesCount': actualFemalesCount,
    });
  }

  Future<RepositoryWriteResult> updateBuyerWaitlistFields({
    required String userId,
    required String buyerId,
    required Map<String, dynamic> fields,
  }) {
    return _waitlistRepo.saveMap(userId, buyerId, fields);
  }

  Future<RepositoryWriteResult> updateDogFields({
    required String userId,
    required String dogId,
    required Map<String, dynamic> fields,
  }) {
    return _dogsRepo.saveMap(userId, dogId, fields);
  }

  // ============ PURCHASE CONTRACTS ============

  /// Save purchase contract to Firestore (flat root collection `contracts/`)
  Future<RepositoryWriteResult> savePurchaseContract({
    required String userId,
    required String contractId,
    required Map<String, dynamic> contractData,
  }) async {
    return _executeWrite(() async {
      final data = {
        ...contractData,
        ..._ownershipFields(userId),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      await _firestore
          .collection('contracts')
          .doc(contractId)
          .set(data, SetOptions(merge: true));
    }, action: 'Error saving contract');
  }

  /// Get all purchase contracts for user
  Future<List<Map<String, dynamic>>> getPurchaseContracts(String userId) async {
    try {
      final querySnapshot = await baseQuery('contracts', userId).get();
      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Error fetching contracts: $e');
    }
  }

  /// Permanently removes the purchase contract document from `contracts/`.
  Future<RepositoryWriteResult> deletePurchaseContract({
    required String userId,
    required String contractId,
  }) async {
    return _executeWrite(() async {
      await _firestore.collection('contracts').doc(contractId).delete();
    }, action: 'Error deleting contract');
  }

  // ============ WEIGHT LOGS ============

  /// Save weight log to Firestore (flat root collection `puppy_weight_logs/`)
  Future<RepositoryWriteResult> saveWeightLog({
    required String userId,
    required String litterId,
    required String puppyId,
    required String logId,
    required Map<String, dynamic> logData,
  }) async {
    return _executeWrite(() async {
      final data = {
        ...logData,
        'puppyId': puppyId,
        'litterId': litterId,
        ..._ownershipFields(userId),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      await _firestore
          .collection('puppy_weight_logs')
          .doc(logId)
          .set(data, SetOptions(merge: true));
    }, action: 'Error saving weight log');
  }

  /// Get all weight logs for a puppy
  Future<List<Map<String, dynamic>>> getWeightLogs({
    required String userId,
    required String litterId,
    required String puppyId,
  }) async {
    try {
      final querySnapshot = await baseQuery('puppy_weight_logs', userId)
          .where('puppyId', isEqualTo: puppyId)
          .orderBy('date', descending: true)
          .get();
      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Error fetching weight logs: $e');
    }
  }

  /// Delete weight log
  Future<RepositoryWriteResult> deleteWeightLog({
    required String userId,
    required String litterId,
    required String puppyId,
    required String logId,
  }) async {
    return _executeWrite(() async {
      await _firestore.collection('puppy_weight_logs').doc(logId).delete();
    }, action: 'Error deleting weight log');
  }
  /// Get real-time updates for dogs (flat root collection)
  Stream<List<Map<String, dynamic>>> dogsStream(String userId) {
    return _dogsRepo
        .baseQuery(userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => doc.data())
            .toList());
  }

  /// Get real-time updates for litters (flat root collection, excludes soft-deleted)
  Stream<List<Map<String, dynamic>>> littersStream(String userId) {
    return _littersRepo
        .baseQuery(userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => doc.data())
            .toList());
  }

  /// Save progesterone measurement to Firestore (flat root `progesterone_measurements/`)
  Future<RepositoryWriteResult> saveProgesteroneMeasurement({
    required String userId,
    required String dogId,
    required String measurementId,
    required Map<String, dynamic> measurementData,
  }) async {
    return _executeWrite(() async {
      final data = {
        ...measurementData,
        'dogId': dogId,
        ..._ownershipFields(userId),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      await _firestore
          .collection('progesterone_measurements')
          .doc(measurementId)
          .set(data, SetOptions(merge: true));
    }, action: 'Error saving progesterone measurement');
  }

  /// Get all progesterone measurements for a dog
  Future<List<Map<String, dynamic>>> getProgesteroneMeasurements({
    required String userId,
    required String dogId,
  }) async {
    try {
      final querySnapshot = await baseQuery('progesterone_measurements', userId)
          .where('dogId', isEqualTo: dogId)
          .orderBy('dateMeasured', descending: true)
          .get();
      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Error fetching progesterone measurements: $e');
    }
  }

  /// Delete progesterone measurement
  Future<RepositoryWriteResult> deleteProgesteroneMeasurement({
    required String userId,
    required String dogId,
    required String measurementId,
  }) async {
    return _executeWrite(() async {
      await _firestore
          .collection('progesterone_measurements')
          .doc(measurementId)
          .delete();
    }, action: 'Error deleting progesterone measurement');
  }

  // ============ HEAT CYCLES ============

  /// Save heat cycle to Firestore (flat root `heat_cycles/`)
  Future<RepositoryWriteResult> saveHeatCycle({
    required String userId,
    required String dogId,
    required String heatCycleId,
    required Map<String, dynamic> heatCycleData,
  }) async {
    return _executeWrite(() async {
      final data = {
        ...heatCycleData,
        'dogId': dogId,
        ..._ownershipFields(userId),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      await _firestore
          .collection('heat_cycles')
          .doc(heatCycleId)
          .set(data, SetOptions(merge: true));
    }, action: 'Error saving heat cycle');
  }

  /// Get all heat cycles for a dog
  Future<List<Map<String, dynamic>>> getHeatCycles({
    required String userId,
    required String dogId,
  }) async {
    try {
      final querySnapshot = await baseQuery('heat_cycles', userId)
          .where('dogId', isEqualTo: dogId)
          .orderBy('date', descending: true)
          .get();
      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Error fetching heat cycles: $e');
    }
  }

  /// Delete heat cycle
  Future<RepositoryWriteResult> deleteHeatCycle({
    required String userId,
    required String dogId,
    required String heatCycleId,
  }) async {
    return _executeWrite(() async {
      await _firestore
          .collection('heat_cycles')
          .doc(heatCycleId)
          .delete();
    }, action: 'Error deleting heat cycle');
  }

  /// Save show result to Firestore (flat root collection `show_results/`)
  Future<RepositoryWriteResult> saveShowResult({
    required String userId,
    required String showResultId,
    required Map<String, dynamic> showResultData,
  }) async {
    return _executeWrite(() async {
      final data = {
        ...showResultData,
        ..._ownershipFields(userId),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      await _firestore
          .collection('show_results')
          .doc(showResultId)
          .set(data, SetOptions(merge: true));
    }, action: 'Error saving show result');
  }

  /// Get all show results for current user/kennel (excludes soft-deleted)
  Future<List<Map<String, dynamic>>> getShowResults(String userId) async {
    try {
      final querySnapshot = await baseQuery('show_results', userId)
          .orderBy('date', descending: true)
          .get();
      return querySnapshot.docs
          .map((doc) => doc.data())
          .where((d) => d['isDeleted'] != true)
          .toList();
    } catch (e) {
      throw Exception('Error fetching show results: $e');
    }
  }

  /// Soft-delete a show result (sets isDeleted=true in Firestore).
  Future<RepositoryWriteResult> deleteShowResult({
    required String userId,
    required String showResultId,
  }) async {
    return _executeWrite(() async {
      await _firestore.collection('show_results').doc(showResultId).update({
        'isDeleted': true,
        'deletedAt': DateTime.now().toIso8601String(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }, action: 'Error soft-deleting show result');
  }

  /// Permanently remove a show result from Firestore.
  /// Call this when permanently deleting from trash.
  Future<RepositoryWriteResult> hardDeleteShowResult({
    required String userId,
    required String showResultId,
  }) async {
    return _executeWrite(() async {
      await _firestore.collection('show_results').doc(showResultId).delete();
    }, action: 'Error hard-deleting show result');
  }

  /// Static helper to save a show result.
  static Future<RepositoryWriteResult> saveShowResultEntry(
    String userId,
    dynamic showResult,
  ) async {
    return FirestoreService().saveShowResult(
      userId: userId,
      showResultId: showResult.id,
      showResultData: showResult.toJson(),
    );
  }

  /// Static helper to delete show result
  static Future<RepositoryWriteResult> removeShowResult(
    String userId,
    String showResultId,
  ) async {
    return FirestoreService().deleteShowResult(
      userId: userId,
      showResultId: showResultId,
    );
  }

  // ============ VET VISITS ============

  /// Save vet visit to Firestore (flat root `vet_visits/`)
  Future<RepositoryWriteResult> saveVetVisit({
    required String userId,
    required String dogId,
    required String visitId,
    required Map<String, dynamic> visitData,
  }) async {
    return _executeWrite(() async {
      final data = {
        ...visitData,
        'dogId': dogId,
        ..._ownershipFields(userId),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      await _firestore
          .collection('vet_visits')
          .doc(visitId)
          .set(data, SetOptions(merge: true));
    }, action: 'Error saving vet visit');
  }

  /// Get all vet visits for a dog
  Future<List<Map<String, dynamic>>> getVetVisits({
    required String userId,
    required String dogId,
  }) async {
    try {
      final querySnapshot = await baseQuery('vet_visits', userId)
          .where('dogId', isEqualTo: dogId)
          .orderBy('visitDate', descending: true)
          .get();
      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Error fetching vet visits: $e');
    }
  }

  /// Delete vet visit
  Future<RepositoryWriteResult> deleteVetVisit({
    required String userId,
    required String dogId,
    required String visitId,
  }) async {
    return _executeWrite(() async {
      await _firestore
          .collection('vet_visits')
          .doc(visitId)
          .delete();
    }, action: 'Error deleting vet visit');
  }

  /// Get all vet visits across all dogs for this user/kennel
  Future<List<Map<String, dynamic>>> getAllVetVisits(String userId) async {
    try {
      final querySnapshot = await baseQuery('vet_visits', userId).get();
      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Error fetching all vet visits: $e');
    }
  }

  // ============ MEDICAL TREATMENTS ============

  /// Save medical treatment to Firestore (flat root `medical_treatments/`)
  Future<RepositoryWriteResult> saveMedicalTreatment({
    required String userId,
    required String dogId,
    required String treatmentId,
    required Map<String, dynamic> treatmentData,
  }) async {
    return _executeWrite(() async {
      final data = {
        ...treatmentData,
        'dogId': dogId,
        ..._ownershipFields(userId),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      await _firestore
          .collection('medical_treatments')
          .doc(treatmentId)
          .set(data, SetOptions(merge: true));
    }, action: 'Error saving medical treatment');
  }

  /// Get all medical treatments for a dog
  Future<List<Map<String, dynamic>>> getMedicalTreatments({
    required String userId,
    required String dogId,
  }) async {
    try {
      final querySnapshot = await baseQuery('medical_treatments', userId)
          .where('dogId', isEqualTo: dogId)
          .orderBy('dateGiven', descending: true)
          .get();
      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Error fetching medical treatments: $e');
    }
  }

  /// Delete medical treatment
  Future<RepositoryWriteResult> deleteMedicalTreatment({
    required String userId,
    required String dogId,
    required String treatmentId,
  }) async {
    return _executeWrite(() async {
      await _firestore
          .collection('medical_treatments')
          .doc(treatmentId)
          .delete();
    }, action: 'Error deleting medical treatment');
  }

  /// Get all medical treatments across all dogs for this user/kennel
  Future<List<Map<String, dynamic>>> getAllMedicalTreatments(String userId) async {
    try {
      final querySnapshot = await baseQuery('medical_treatments', userId).get();
      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Error fetching all medical treatments: $e');
    }
  }

  // ============ DNA TESTS ============

  /// Save DNA test to Firestore (flat root `dna_tests/`)
  Future<RepositoryWriteResult> saveDnaTest({
    required String userId,
    required String dogId,
    required String testId,
    required Map<String, dynamic> testData,
  }) async {
    return _executeWrite(() async {
      final data = {
        ...testData,
        'dogId': dogId,
        ..._ownershipFields(userId),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      await _firestore
          .collection('dna_tests')
          .doc(testId)
          .set(data, SetOptions(merge: true));
    }, action: 'Error saving DNA test');
  }

  /// Get all DNA tests for a dog
  Future<List<Map<String, dynamic>>> getDnaTests({
    required String userId,
    required String dogId,
  }) async {
    try {
      final querySnapshot = await baseQuery('dna_tests', userId)
          .where('dogId', isEqualTo: dogId)
          .orderBy('testDate', descending: true)
          .get();
      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Error fetching DNA tests: $e');
    }
  }

  /// Delete DNA test
  Future<RepositoryWriteResult> deleteDnaTest({
    required String userId,
    required String dogId,
    required String testId,
  }) async {
    return _executeWrite(() async {
      await _firestore
          .collection('dna_tests')
          .doc(testId)
          .delete();
    }, action: 'Error deleting DNA test');
  }

  /// Get all DNA tests across all dogs for this user/kennel
  Future<List<Map<String, dynamic>>> getAllDnaTests(String userId) async {
    try {
      final querySnapshot = await baseQuery('dna_tests', userId).get();
      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Error fetching all DNA tests: $e');
    }
  }

  // ============ WEIGHT RECORDS ============

  /// Save weight record to Firestore (flat root `weight_records/`)
  Future<RepositoryWriteResult> saveWeightRecord({
    required String userId,
    required String dogId,
    required String recordId,
    required Map<String, dynamic> recordData,
  }) async {
    return _executeWrite(() async {
      final data = {
        ...recordData,
        'dogId': dogId,
        ..._ownershipFields(userId),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      await _firestore
          .collection('weight_records')
          .doc(recordId)
          .set(data, SetOptions(merge: true));
    }, action: 'Error saving weight record');
  }

  /// Get all weight records for a dog
  Future<List<Map<String, dynamic>>> getWeightRecords({
    required String userId,
    required String dogId,
  }) async {
    try {
      final querySnapshot = await baseQuery('weight_records', userId)
          .where('dogId', isEqualTo: dogId)
          .orderBy('date', descending: true)
          .get();
      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Error fetching weight records: $e');
    }
  }

  /// Delete weight record
  Future<RepositoryWriteResult> deleteWeightRecord({
    required String userId,
    required String dogId,
    required String recordId,
  }) async {
    return _executeWrite(() async {
      await _firestore
          .collection('weight_records')
          .doc(recordId)
          .delete();
    }, action: 'Error deleting weight record');
  }

  /// Get all weight records across all dogs for this user/kennel
  Future<List<Map<String, dynamic>>> getAllWeightRecords(String userId) async {
    try {
      final querySnapshot = await baseQuery('weight_records', userId).get();
      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Error fetching all weight records: $e');
    }
  }

  /// Save delivery checklist to Firestore (flat root `delivery_checklists/`)
  Future<RepositoryWriteResult> saveDeliveryChecklist(
    dynamic checklist,
    String userId,
  ) async {
    return _executeWrite(() async {
      final data = <String, dynamic>{
        ...(checklist.toJson() as Map<String, dynamic>),
        ..._ownershipFields(userId),
      };
      await _firestore
          .collection('delivery_checklists')
          .doc(checklist.id)
          .set(data, SetOptions(merge: true));
    }, action: 'Error saving delivery checklist');
  }

  /// Get delivery checklist from cloud
  Future<Map<String, dynamic>?> getDeliveryChecklist({
    required String userId,
    required String puppyId,
  }) async {
    try {
      final querySnapshot = await baseQuery('delivery_checklists', userId)
          .where('puppyId', isEqualTo: puppyId)
          .limit(1)
          .get();
      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.data();
      }
      return null;
    } catch (e) {
      AppLogger.debug('Error getting delivery checklist: $e');
      return null;
    }
  }

  /// Get all delivery checklists
  Future<List<Map<String, dynamic>>> getAllDeliveryChecklists(String userId) async {
    try {
      final querySnapshot = await baseQuery('delivery_checklists', userId).get();
      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      AppLogger.debug('Error getting all delivery checklists: $e');
      return [];
    }
  }

  // ============ TREATMENT PLANS ============

  /// Save treatment plan to Firestore (flat root `treatment_plans/`)
  Future<RepositoryWriteResult> saveTreatmentPlan({
    required String userId,
    required String treatmentPlanId,
    required Map<String, dynamic> treatmentPlanData,
  }) async {
    return _executeWrite(() async {
      final data = {
        ...treatmentPlanData,
        ..._ownershipFields(userId),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      await _firestore
          .collection('treatment_plans')
          .doc(treatmentPlanId)
          .set(data, SetOptions(merge: true));
    }, action: 'Error saving treatment plan');
  }

  /// Get all treatment plans for user
  Future<List<Map<String, dynamic>>> getTreatmentPlans(String userId) async {
    try {
      final querySnapshot = await baseQuery('treatment_plans', userId).get();
      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Error fetching treatment plans: $e');
    }
  }

  /// Delete treatment plan
  Future<RepositoryWriteResult> deleteTreatmentPlan({
    required String userId,
    required String treatmentPlanId,
  }) async {
    return _executeWrite(() async {
      await _firestore.collection('treatment_plans').doc(treatmentPlanId).delete();
    }, action: 'Error deleting treatment plan');
  }

  // ============ BREEDING CONTRACTS ============

  /// Save breeding contract to Firestore (flat root `breeding_contracts/`)
  Future<RepositoryWriteResult> saveBreedingContract({
    required String userId,
    required String contractId,
    required Map<String, dynamic> contractData,
  }) async {
    return _executeWrite(() async {
      final data = {
        ...contractData,
        ..._ownershipFields(userId),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      await _firestore
          .collection('breeding_contracts')
          .doc(contractId)
          .set(data, SetOptions(merge: true));
    }, action: 'Error saving breeding contract');
  }

  /// Get all breeding contracts for user
  Future<List<Map<String, dynamic>>> getBreedingContracts(String userId) async {
    try {
      final querySnapshot = await baseQuery('breeding_contracts', userId).get();
      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Error fetching breeding contracts: $e');
    }
  }

  /// Delete breeding contract
  Future<RepositoryWriteResult> deleteBreedingContract({
    required String userId,
    required String contractId,
  }) async {
    return _executeWrite(() async {
      await _firestore.collection('breeding_contracts').doc(contractId).delete();
    }, action: 'Error deleting breeding contract');
  }

  // ============ CO-OWNERSHIP CONTRACTS ============

  /// Save co-ownership contract to Firestore (flat root `co_ownership_contracts/`)
  Future<RepositoryWriteResult> saveCoOwnershipContract({
    required String userId,
    required String contractId,
    required Map<String, dynamic> contractData,
  }) async {
    return _executeWrite(() async {
      final data = {
        ...contractData,
        ..._ownershipFields(userId),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      await _firestore
          .collection('co_ownership_contracts')
          .doc(contractId)
          .set(data, SetOptions(merge: true));
    }, action: 'Error saving co-ownership contract');
  }

  /// Get all co-ownership contracts for user
  Future<List<Map<String, dynamic>>> getCoOwnershipContracts(String userId) async {
    try {
      final querySnapshot = await baseQuery('co_ownership_contracts', userId).get();
      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Error fetching co-ownership contracts: $e');
    }
  }

  /// Delete co-ownership contract
  Future<RepositoryWriteResult> deleteCoOwnershipContract({
    required String userId,
    required String contractId,
  }) async {
    return _executeWrite(() async {
      await _firestore.collection('co_ownership_contracts').doc(contractId).delete();
    }, action: 'Error deleting co-ownership contract');
  }

  // ============ FOSTER CONTRACTS ============

  /// Save foster contract to Firestore (flat root `foster_contracts/`)
  Future<RepositoryWriteResult> saveFosterContract({
    required String userId,
    required String contractId,
    required Map<String, dynamic> contractData,
  }) async {
    return _executeWrite(() async {
      final data = {
        ...contractData,
        ..._ownershipFields(userId),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      await _firestore
          .collection('foster_contracts')
          .doc(contractId)
          .set(data, SetOptions(merge: true));
    }, action: 'Error saving foster contract');
  }

  /// Get all foster contracts for user
  Future<List<Map<String, dynamic>>> getFosterContracts(String userId) async {
    try {
      final querySnapshot = await baseQuery('foster_contracts', userId).get();
      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Error fetching foster contracts: $e');
    }
  }

  /// Delete foster contract
  Future<RepositoryWriteResult> deleteFosterContract({
    required String userId,
    required String contractId,
  }) async {
    return _executeWrite(() async {
      await _firestore.collection('foster_contracts').doc(contractId).delete();
    }, action: 'Error deleting foster contract');
  }

  // ============ RESERVATION CONTRACTS ============

  /// Save reservation contract to Firestore (flat root `reservation_contracts/`)
  Future<RepositoryWriteResult> saveReservationContract({
    required String userId,
    required String contractId,
    required Map<String, dynamic> contractData,
  }) async {
    return _executeWrite(() async {
      final data = {
        ...contractData,
        ..._ownershipFields(userId),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      await _firestore
          .collection('reservation_contracts')
          .doc(contractId)
          .set(data, SetOptions(merge: true));
    }, action: 'Error saving reservation contract');
  }

  /// Get all reservation contracts for user
  Future<List<Map<String, dynamic>>> getReservationContracts(String userId) async {
    try {
      final querySnapshot = await baseQuery('reservation_contracts', userId).get();
      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Error fetching reservation contracts: $e');
    }
  }

  /// Delete reservation contract
  Future<RepositoryWriteResult> deleteReservationContract({
    required String userId,
    required String contractId,
  }) async {
    return _executeWrite(() async {
      await _firestore.collection('reservation_contracts').doc(contractId).delete();
    }, action: 'Error deleting reservation contract');
  }

  // ============ CUSTOM CONTRACT TERMS ============

  /// Save a custom contract term to Firestore (flat root `custom_terms/`)
  Future<RepositoryWriteResult> saveCustomTerm({
    required String userId,
    required String termId,
    required Map<String, dynamic> termData,
  }) async {
    return _executeWrite(() async {
      final data = {
        ...termData,
        ..._ownershipFields(userId),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      await _firestore
          .collection('custom_terms')
          .doc(termId)
          .set(data, SetOptions(merge: true));
    }, action: 'Error saving custom term');
  }

  /// Get all custom terms for user
  Future<List<Map<String, dynamic>>> getCustomTerms(String userId) async {
    try {
      final querySnapshot = await baseQuery('custom_terms', userId).get();
      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Error fetching custom terms: $e');
    }
  }

  /// Delete a custom term
  Future<RepositoryWriteResult> deleteCustomTerm({
    required String userId,
    required String termId,
  }) async {
    return _executeWrite(() async {
      await _firestore.collection('custom_terms').doc(termId).delete();
    }, action: 'Error deleting custom term');
  }

  // ============ GALLERY IMAGES ============

  /// Save gallery image metadata to Firestore (flat root `gallery_images/`).
  /// The actual image bytes live in Firebase Storage; only the URL + metadata are stored here.
  Future<RepositoryWriteResult> saveGalleryImage({
    required String userId,
    required String litterId,
    required String imageId,
    required Map<String, dynamic> imageData,
  }) async {
    return _executeWrite(() async {
      final data = {
        ...imageData,
        'litterId': litterId,
        ..._ownershipFields(userId),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      await _firestore
          .collection('gallery_images')
          .doc(imageId)
          .set(data, SetOptions(merge: true));
    }, action: 'Error saving gallery image metadata');
  }

  /// Get all gallery image metadata for a litter.
  Future<List<Map<String, dynamic>>> getGalleryImages({
    required String userId,
    required String litterId,
  }) async {
    try {
      final querySnapshot = await baseQuery('gallery_images', userId)
          .where('litterId', isEqualTo: litterId)
          .orderBy('dateAdded', descending: true)
          .get();
      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Error fetching gallery images: $e');
    }
  }

  /// Delete gallery image metadata from Firestore.
  Future<RepositoryWriteResult> deleteGalleryImage({
    required String userId,
    required String litterId,
    required String imageId,
  }) async {
    return _executeWrite(() async {
      await _firestore
          .collection('gallery_images')
          .doc(imageId)
          .delete();
    }, action: 'Error deleting gallery image metadata');
  }

  // ============ USER PREFERENCES ============

  /// Save user preferences to Firestore (followed breeds, display name, etc.)
  Future<RepositoryWriteResult> saveUserPreferences({
    required String userId,
    required Map<String, dynamic> prefsData,
  }) async {
    return _executeWrite(() async {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc('preferences')
          .set(prefsData, SetOptions(merge: true));
    }, action: 'Error saving user preferences');
  }

  /// Get user preferences from Firestore.
  Future<Map<String, dynamic>?> getUserPreferences(String userId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc('preferences')
          .get();
      return doc.data();
    } catch (e) {
      throw Exception('Error fetching user preferences: $e');
    }
  }

  // ============ ONE-TIME MIGRATION ============

  /// Migrates dogs, litters, and show_results from the old nested paths
  /// (breeding_groups/{kennelId}/... or users/{userId}/...) to the new flat
  /// root collections (dogs/, litters/, show_results/).
  ///
  /// Each migrated document gets `ownerId` and `kennelId` fields injected.
  /// The migration flag is stored in Firestore so it only runs once per user
  /// across all their devices.
  Future<RepositoryWriteResult> migrateToFlatCollections(String userId) async {
    try {
      // Check if migration already completed for this user
      final flagRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('migration')
          .doc('flat_collections_v2');

      final flagDoc = await flagRef.get();
      if (flagDoc.exists && (flagDoc.data()?['done'] == true)) {
        debugPrint('[MIGRATE] flat_collections_v2 already done — skipping');
        return RepositoryWriteResult.success();
      }

      debugPrint('[MIGRATE] Starting migration to flat root collections...');

      final kennelId = KennelService().activeKennelId;

      // Build list of old base document references to migrate from
      final oldBaseDocs = <DocumentReference>[];
      if (kennelId != null && kennelId.isNotEmpty) {
        oldBaseDocs.add(_firestore.collection('breeding_groups').doc(kennelId));
      }
      oldBaseDocs.add(_firestore.collection('users').doc(userId));

      int dogsMigrated = 0;
      int littersMigrated = 0;
      int showResultsMigrated = 0;
      int puppiesMigrated = 0;
      int temperatureRecordsMigrated = 0;
      int galleryImagesMigrated = 0;
      var hadErrors = false;

      for (final baseDoc in oldBaseDocs) {
        final sourceKennelId =
            baseDoc.parent.id == 'breeding_groups' ? baseDoc.id : null;
        final ownership = {
          'ownerId': userId,
          'kennelId': sourceKennelId,
        };

        // ── Dogs ────────────────────────────────────────────────────────────
        try {
          final dogsSnap = await baseDoc.collection('dogs').get();
          for (final dogDoc in dogsSnap.docs) {
            final data = {...dogDoc.data(), ...ownership};
            data['isDeleted'] ??= false;
            await _firestore
                .collection('dogs')
                .doc(dogDoc.id)
                .set(data, SetOptions(merge: true));
            dogsMigrated++;
          }
        } catch (e) {
          hadErrors = true;
          debugPrint('[MIGRATE] Error migrating dogs from ${baseDoc.path}: $e');
        }

        // ── Litters (+ puppies subcollection) ────────────────────────────────
        try {
          final littersSnap = await baseDoc.collection('litters').get();
          for (final litterDoc in littersSnap.docs) {
            final data = {...litterDoc.data(), ...ownership};
            data['isDeleted'] ??= false;
            final newLitterRef =
                _firestore.collection('litters').doc(litterDoc.id);
            await newLitterRef.set(data, SetOptions(merge: true));
            littersMigrated++;

            // Migrate puppies subcollection
            try {
              final puppiesSnap = await litterDoc.reference
                  .collection('puppies')
                  .get();
              for (final puppyDoc in puppiesSnap.docs) {
                final puppyData = {
                  ...puppyDoc.data(),
                  ...ownership,
                  'litterId': litterDoc.id,
                };
                puppyData['isDeleted'] ??= false;
                await _firestore
                    .collection('puppies')
                    .doc(puppyDoc.id)
                    .set(puppyData, SetOptions(merge: true));
                puppiesMigrated++;
              }
            } catch (e) {
              hadErrors = true;
              debugPrint(
                  '[MIGRATE] Error migrating puppies from ${litterDoc.reference.path}: $e');
            }

            // Migrate temperature_records subcollection
            try {
              final tempSnap = await litterDoc.reference
                  .collection('temperature_records')
                  .get();
              for (final tempDoc in tempSnap.docs) {
                final tempData = {
                  ...tempDoc.data(),
                  ...ownership,
                  'litterId': litterDoc.id,
                };
                tempData['isDeleted'] ??= false;
                await _firestore
                    .collection('temperature_records')
                    .doc(tempDoc.id)
                    .set(tempData, SetOptions(merge: true));
                temperatureRecordsMigrated++;
              }
            } catch (e) {
              hadErrors = true;
              debugPrint(
                  '[MIGRATE] Error migrating temperature_records from ${litterDoc.reference.path}: $e');
            }

            // Migrate gallery_images subcollection
            try {
              final gallerySnap = await litterDoc.reference
                  .collection('gallery_images')
                  .get();
              for (final imgDoc in gallerySnap.docs) {
                final imageData = {
                  ...imgDoc.data(),
                  ...ownership,
                  'litterId': litterDoc.id,
                };
                imageData['isDeleted'] ??= false;
                await _firestore
                    .collection('gallery_images')
                    .doc(imgDoc.id)
                    .set(imageData, SetOptions(merge: true));
                galleryImagesMigrated++;
              }
            } catch (e) {
              hadErrors = true;
              debugPrint(
                  '[MIGRATE] Error migrating gallery_images from ${litterDoc.reference.path}: $e');
            }
          }
        } catch (e) {
          hadErrors = true;
          debugPrint('[MIGRATE] Error migrating litters from ${baseDoc.path}: $e');
        }

        // ── Show results ─────────────────────────────────────────────────────
        try {
          final showSnap = await baseDoc.collection('show_results').get();
          for (final showDoc in showSnap.docs) {
            final data = {...showDoc.data(), ...ownership};
            data['isDeleted'] ??= false;
            await _firestore
                .collection('show_results')
                .doc(showDoc.id)
                .set(data, SetOptions(merge: true));
            showResultsMigrated++;
          }
        } catch (e) {
          hadErrors = true;
          debugPrint(
              '[MIGRATE] Error migrating show_results from ${baseDoc.path}: $e');
        }
      }

      if (hadErrors) {
        return RepositoryWriteResult.failure(
          message: 'Migration incomplete; will retry on next startup',
        );
      }

      // Mark migration as done
      await flagRef.set({
        'done': true,
        'completedAt': FieldValue.serverTimestamp(),
        'dogsMigrated': dogsMigrated,
        'littersMigrated': littersMigrated,
        'puppiesMigrated': puppiesMigrated,
        'temperatureRecordsMigrated': temperatureRecordsMigrated,
        'galleryImagesMigrated': galleryImagesMigrated,
        'showResultsMigrated': showResultsMigrated,
      });

      debugPrint(
          '[MIGRATE] Done: $dogsMigrated dogs, $littersMigrated litters, $puppiesMigrated puppies, $temperatureRecordsMigrated temperature records, $galleryImagesMigrated gallery images, $showResultsMigrated show results migrated to flat collections.');
      return RepositoryWriteResult.success();
    } catch (e) {
      // Migration is non-critical — app continues with whatever data is available
      debugPrint('[MIGRATE] Migration error (non-fatal): $e');
      return RepositoryWriteResult.failure(
        message: 'Migration error (non-fatal)',
        error: e,
      );
    }
  }

  // ============ BATCH OPERATIONS ============

  /// Applies a batch soft-delete to a flat root collection using a single
  /// atomic Firestore WriteBatch — at most 500 operations per batch,
  /// automatically chunked for larger sets.
  ///
  /// Use this when multiple deletions must be applied efficiently at once.
  Future<RepositoryWriteResult> batchSoftDelete({
    required String collection,
    required List<String> docIds,
  }) async {
    if (docIds.isEmpty) return RepositoryWriteResult.success();
    const maxBatch = 500;
    for (var i = 0; i < docIds.length; i += maxBatch) {
      final chunk = docIds.sublist(i, (i + maxBatch).clamp(0, docIds.length));
      final batch = _firestore.batch();
      for (final id in chunk) {
        batch.update(_firestore.collection(collection).doc(id), {
          'isDeleted': true,
          'deletedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    }
    return RepositoryWriteResult.success();
  }

  // ============ KENNEL ANALYTICS ============

  /// Fetches the pre-computed financial analytics summary written by the Cloud
  /// Function (`onFinancialWrite`).
  ///
  /// Path: `breeding_groups/{kennelId}/analytics/finance`
  ///       or `users/{userId}/analytics/finance` for private users.
  Future<KennelAnalytics?> fetchKennelAnalytics(String userId) async {
    try {
      final baseDoc = _getBaseDoc(userId);
      final docSnap = await baseDoc.collection('analytics').doc('finance').get();
      if (!docSnap.exists || docSnap.data() == null) return null;
      final json = Map<String, dynamic>.from(docSnap.data()!);
      // Inject the id so the model can self-identify
      final kennelId = KennelService().activeKennelId;
      json['id'] = (kennelId != null && kennelId.isNotEmpty) ? kennelId : userId;
      return KennelAnalytics.fromJson(json);
    } catch (e) {
      AppLogger.debug('fetchKennelAnalytics error (non-fatal): $e');
      return null;
    }
  }

  /// Returns a real-time stream of the financial analytics summary.
  Stream<KennelAnalytics?> analyticsStream(String userId) {
    final baseDoc = _getBaseDoc(userId);
    final kennelId = KennelService().activeKennelId;
    final analyticsId =
        (kennelId != null && kennelId.isNotEmpty) ? kennelId : userId;
    return baseDoc
        .collection('analytics')
        .doc('finance')
        .snapshots()
        .map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      final json = Map<String, dynamic>.from(snap.data()!);
      json['id'] = analyticsId;
      return KennelAnalytics.fromJson(json);
    });
  }

  /// Recovery utility: reassign docs to the current user when `ownerEmail`
  /// matches but `ownerId` points to an old/different Firebase UID.
  ///
  /// Returns number of updated docs. Safe to call repeatedly.
  Future<int> recoverOwnershipFromEmail({
    required String userId,
    required String userEmail,
  }) async {
    final email = userEmail.trim().toLowerCase();
    if (email.isEmpty) return 0;

    const collections = [
      'dogs',
      'litters',
      'puppies',
      'buyers',
      'show_results',
      'expenses',
      'income',
      'health_info',
      'vaccines',
      'matings',
      'vet_visits',
      'medical_treatments',
      'dna_tests',
      'weight_records',
      'progesterone_measurements',
      'heat_cycles',
      'gallery_images',
      'puppy_weight_logs',
      'temperature_records',
      'contracts',
      'treatment_plans',
      'breeding_contracts',
      'co_ownership_contracts',
      'foster_contracts',
      'reservation_contracts',
      'custom_terms',
    ];

    int updated = 0;

    for (final collection in collections) {
      try {
        final snap = await _firestore
            .collection(collection)
            .where('ownerEmail', isEqualTo: email)
            .limit(200)
            .get();

        if (snap.docs.isEmpty) continue;

        WriteBatch batch = _firestore.batch();
        int opCount = 0;

        for (final doc in snap.docs) {
          final data = doc.data();
          if ((data['ownerId'] as String?) == userId) continue;
          batch.update(doc.reference, {
            'ownerId': userId,
            'ownerEmail': email,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          updated++;
          opCount++;
          if (opCount >= 450) {
            await batch.commit();
            batch = _firestore.batch();
            opCount = 0;
          }
        }

        if (opCount > 0) {
          await batch.commit();
        }
      } catch (e) {
        AppLogger.debug('recoverOwnershipFromEmail failed for $collection: $e');
      }
    }

    AppLogger.debug('recoverOwnershipFromEmail updated $updated docs for $email');
    return updated;
  }

  /// Backend fail-safe reconciliation:
  /// - repairs ownerId/ownerEmail by authenticated email
  /// - restores users/{uid}/kennels links
  /// - repairs missing breeding_groups/{kennelId}/members/{uid}
  Future<RepositoryWriteResult> repairUserIdentityOnServer() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return RepositoryWriteResult.success();
      final token = await user.getIdToken(true);
      if (token == null || token.isEmpty) {
        return RepositoryWriteResult.failure(
          message: 'Missing auth token for identity repair',
        );
      }

      final response = await http
          .post(
            Uri.parse(_repairUserIdentityUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({}),
          )
          .timeout(const Duration(seconds: 90));

      if (response.statusCode != 200) {
        AppLogger.debug(
            'repairUserIdentityOnServer failed (${response.statusCode}): ${response.body}');
        return RepositoryWriteResult.failure(
          errorCode: '${response.statusCode}',
          message: 'repairUserIdentityOnServer failed',
          error: response.body,
        );
      } else {
        AppLogger.debug('repairUserIdentityOnServer success');
        return RepositoryWriteResult.success();
      }
    } catch (e) {
      AppLogger.debug('repairUserIdentityOnServer error: $e');
      return RepositoryWriteResult.failure(
        message: 'repairUserIdentityOnServer error',
        error: e,
      );
    }
  }
}

typedef CloudSyncService = FirestoreService;

