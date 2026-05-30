import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:breedly/utils/logger.dart';
import 'package:breedly/services/kennel_service.dart';

class CloudSyncService {
  static final CloudSyncService _instance = CloudSyncService._internal();

  factory CloudSyncService() {
    return _instance;
  }

  CloudSyncService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get the base document reference - uses kennel if available, falls back to user
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
  Future<void> saveUserProfile({
    required String userId,
    required String email,
    required String displayName,
    String? photoUrl,
  }) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);
      await userRef.set({
        'email': email,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Feil ved lagring av profil: $e');
    }
  }

  /// Get user profile
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.data();
    } catch (e) {
      throw Exception('Feil ved henting av profil: $e');
    }
  }

  /// Save dog to Firestore
  Future<void> saveDog({
    required String userId,
    required String dogId,
    required Map<String, dynamic> dogData,
  }) async {
    try {
      final baseDoc = _getBaseDoc(userId);
      await baseDoc
          .collection('dogs')
          .doc(dogId)
          .set(dogData, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Feil ved lagring av hund: $e');
    }
  }

  /// Get all dogs for user
  Future<List<Map<String, dynamic>>> getDogs(String userId) async {
    try {
      final baseDoc = _getBaseDoc(userId);
      final querySnapshot = await baseDoc.collection('dogs').get();
      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Feil ved henting av hunder: $e');
    }
  }

  /// Save litter to Firestore
  Future<void> saveLitter({
    required String userId,
    required String litterId,
    required Map<String, dynamic> litterData,
  }) async {
    try {
      final baseDoc = _getBaseDoc(userId);
      await baseDoc
          .collection('litters')
          .doc(litterId)
          .set(litterData, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Feil ved lagring av kull: $e');
    }
  }

  /// Get all litters for user
  Future<List<Map<String, dynamic>>> getLitters(String userId) async {
    try {
      final baseDoc = _getBaseDoc(userId);
      final querySnapshot = await baseDoc.collection('litters').get();
      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Feil ved henting av kull: $e');
    }
  }

  /// Save puppy to Firestore
  Future<void> savePuppy({
    required String userId,
    required String litterId,
    required String puppyId,
    required Map<String, dynamic> puppyData,
  }) async {
    try {
      final baseDoc = _getBaseDoc(userId);
      await baseDoc
          .collection('litters')
          .doc(litterId)
          .collection('puppies')
          .doc(puppyId)
          .set(puppyData, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Feil ved lagring av valp: $e');
    }
  }

  /// Get all puppies for a litter
  Future<List<Map<String, dynamic>>> getPuppies({
    required String userId,
    required String litterId,
  }) async {
    try {
      final baseDoc = _getBaseDoc(userId);
      final querySnapshot = await baseDoc
          .collection('litters')
          .doc(litterId)
          .collection('puppies')
          .get();
      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Feil ved henting av valper: $e');
    }
  }

  /// Save income to Firestore
  Future<void> saveIncome({
    required String userId,
    required String incomeId,
    required Map<String, dynamic> incomeData,
  }) async {
    try {
      final baseDoc = _getBaseDoc(userId);
      await baseDoc
          .collection('income')
          .doc(incomeId)
          .set(incomeData, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Feil ved lagring av inntekt: $e');
    }
  }

  /// Get all income for user
  Future<List<Map<String, dynamic>>> getIncome(String userId) async {
    try {
      final baseDoc = _getBaseDoc(userId);
      final querySnapshot = await baseDoc
          .collection('income')
          .orderBy('date', descending: true)
          .get();
      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Feil ved henting av inntekter: $e');
    }
  }

  /// Save expense to Firestore
  Future<void> saveExpense({
    required String userId,
    required String expenseId,
    required Map<String, dynamic> expenseData,
  }) async {
    try {
      final baseDoc = _getBaseDoc(userId);
      await baseDoc
          .collection('expenses')
          .doc(expenseId)
          .set(expenseData, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Feil ved lagring av utgift: $e');
    }
  }

  /// Get all expenses for user
  Future<List<Map<String, dynamic>>> getExpenses(String userId) async {
    try {
      final baseDoc = _getBaseDoc(userId);
      final querySnapshot = await baseDoc
          .collection('expenses')
          .orderBy('date', descending: true)
          .get();
      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Feil ved henting av utgifter: $e');
    }
  }

  /// Save health info to Firestore
  Future<void> saveHealthInfo({
    required String userId,
    required String dogId,
    required String healthInfoId,
    required Map<String, dynamic> healthInfoData,
  }) async {
    try {
      final baseDoc = _getBaseDoc(userId);
      await baseDoc
          .collection('dogs')
          .doc(dogId)
          .collection('health_info')
          .doc(healthInfoId)
          .set(healthInfoData, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Feil ved lagring av helseinformasjon: $e');
    }
  }

  /// Get all health info for a dog
  Future<List<Map<String, dynamic>>> getHealthInfo({
    required String userId,
    required String dogId,
  }) async {
    try {
      final baseDoc = _getBaseDoc(userId);
      final querySnapshot = await baseDoc
          .collection('dogs')
          .doc(dogId)
          .collection('health_info')
          .get();
      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Feil ved henting av helseinformasjon: $e');
    }
  }

  /// Save vaccine to Firestore
  Future<void> saveVaccine({
    required String userId,
    required String dogId,
    required String vaccineId,
    required Map<String, dynamic> vaccineData,
  }) async {
    try {
      final baseDoc = _getBaseDoc(userId);
      await baseDoc
          .collection('dogs')
          .doc(dogId)
          .collection('vaccines')
          .doc(vaccineId)
          .set(vaccineData, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Feil ved lagring av vaksine: $e');
    }
  }

  /// Get all vaccines for a dog
  Future<List<Map<String, dynamic>>> getVaccines({
    required String userId,
    required String dogId,
  }) async {
    try {
      final baseDoc = _getBaseDoc(userId);
      final querySnapshot = await baseDoc
          .collection('dogs')
          .doc(dogId)
          .collection('vaccines')
          .get();
      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Feil ved henting av vaksiner: $e');
    }
  }

  /// Delete dog
  Future<void> deleteDog({
    required String userId,
    required String dogId,
  }) async {
    try {
      final baseDoc = _getBaseDoc(userId);
      await baseDoc.collection('dogs').doc(dogId).delete();
    } catch (e) {
      throw Exception('Feil ved sletting av hund: $e');
    }
  }

  /// Delete litter
  Future<void> deleteLitter({
    required String userId,
    required String litterId,
  }) async {
    try {
      final baseDoc = _getBaseDoc(userId);
      await baseDoc.collection('litters').doc(litterId).delete();
    } catch (e) {
      throw Exception('Feil ved sletting av kull: $e');
    }
  }

  /// Delete puppy
  Future<void> deletePuppy({
    required String userId,
    required String litterId,
    required String puppyId,
  }) async {
    try {
      final baseDoc = _getBaseDoc(userId);
      await baseDoc
          .collection('litters')
          .doc(litterId)
          .collection('puppies')
          .doc(puppyId)
          .delete();
    } catch (e) {
      throw Exception('Feil ved sletting av valp: $e');
    }
  }

  /// Delete expense
  Future<void> deleteExpense({
    required String userId,
    required String expenseId,
  }) async {
    try {
      final baseDoc = _getBaseDoc(userId);
      await baseDoc.collection('expenses').doc(expenseId).delete();
    } catch (e) {
      throw Exception('Feil ved sletting av utgift: $e');
    }
  }

  /// Delete income
  Future<void> deleteIncome({
    required String userId,
    required String incomeId,
  }) async {
    try {
      final baseDoc = _getBaseDoc(userId);
      await baseDoc.collection('income').doc(incomeId).delete();
    } catch (e) {
      throw Exception('Feil ved sletting av inntekt: $e');
    }
  }

  /// Delete health info
  Future<void> deleteHealthInfo({
    required String userId,
    required String dogId,
    required String healthInfoId,
  }) async {
    try {
      final baseDoc = _getBaseDoc(userId);
      await baseDoc
          .collection('dogs')
          .doc(dogId)
          .collection('health_info')
          .doc(healthInfoId)
          .delete();
    } catch (e) {
      throw Exception('Feil ved sletting av helseinformasjon: $e');
    }
  }

  /// Delete vaccine
  Future<void> deleteVaccine({
    required String userId,
    required String dogId,
    required String vaccineId,
  }) async {
    try {
      final baseDoc = _getBaseDoc(userId);
      await baseDoc
          .collection('dogs')
          .doc(dogId)
          .collection('vaccines')
          .doc(vaccineId)
          .delete();
    } catch (e) {
      throw Exception('Feil ved sletting av vaksine: $e');
    }
  }

  // ============ KENNEL PROFILE ============

  /// Save kennel profile to Firestore
  Future<void> saveKennelProfile({
    required String userId,
    required Map<String, dynamic> profileData,
  }) async {
    try {
      final baseDoc = _getBaseDoc(userId);
      await baseDoc
          .collection('kennel_profile')
          .doc('profile')
          .set(profileData, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Feil ved lagring av kennelprofil: $e');
    }
  }

  /// Get kennel profile from Firestore
  Future<Map<String, dynamic>?> getKennelProfile(String userId) async {
    try {
      final baseDoc = _getBaseDoc(userId);
      final doc = await baseDoc
          .collection('kennel_profile')
          .doc('profile')
          .get();
      return doc.data();
    } catch (e) {
      throw Exception('Feil ved henting av kennelprofil: $e');
    }
  }

  // ============ BUYERS ============

  /// Save buyer to Firestore
  Future<void> saveBuyer({
    required String userId,
    required String buyerId,
    required Map<String, dynamic> buyerData,
  }) async {
    try {
      final baseDoc = _getBaseDoc(userId);
      await baseDoc
          .collection('buyers')
          .doc(buyerId)
          .set(buyerData, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Feil ved lagring av kjøper: $e');
    }
  }

  /// Get all buyers for user
  Future<List<Map<String, dynamic>>> getBuyers(String userId) async {
    try {
      final baseDoc = _getBaseDoc(userId);
      final querySnapshot = await baseDoc.collection('buyers').get();
      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Feil ved henting av kjøpere: $e');
    }
  }

  /// Delete buyer
  Future<void> deleteBuyer({
    required String userId,
    required String buyerId,
  }) async {
    try {
      final baseDoc = _getBaseDoc(userId);
      await baseDoc.collection('buyers').doc(buyerId).delete();
    } catch (e) {
      throw Exception('Feil ved sletting av kjøper: $e');
    }
  }

  // ============ MATINGS ============

  /// Save mating to Firestore
  Future<void> saveMating({
    required String userId,
    required String dogId,
    required String matingId,
    required Map<String, dynamic> matingData,
  }) async {
    try {
      final baseDoc = _getBaseDoc(userId);
      await baseDoc
          .collection('dogs')
          .doc(dogId)
          .collection('matings')
          .doc(matingId)
          .set(matingData, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Feil ved lagring av parring: $e');
    }
  }

  /// Get all matings for a dog
  Future<List<Map<String, dynamic>>> getMatings({
    required String userId,
    required String dogId,
  }) async {
    try {
      final baseDoc = _getBaseDoc(userId);
      final querySnapshot = await baseDoc
          .collection('dogs')
          .doc(dogId)
          .collection('matings')
          .get();
      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Feil ved henting av parringer: $e');
    }
  }

  /// Delete mating
  Future<void> deleteMating({
    required String userId,
    required String dogId,
    required String matingId,
  }) async {
    try {
      final baseDoc = _getBaseDoc(userId);
      await baseDoc
          .collection('dogs')
          .doc(dogId)
          .collection('matings')
          .doc(matingId)
          .delete();
    } catch (e) {
      throw Exception('Feil ved sletting av parring: $e');
    }
  }

  // ============ TEMPERATURE RECORDS ============

  /// Save temperature record to Firestore
  Future<void> saveTemperatureRecord({
    required String userId,
    required String litterId,
    required String recordId,
    required Map<String, dynamic> recordData,
  }) async {
    try {
      final baseDoc = _getBaseDoc(userId);
      await baseDoc
          .collection('litters')
          .doc(litterId)
          .collection('temperature_records')
          .doc(recordId)
          .set(recordData, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Feil ved lagring av temperaturmåling: $e');
    }
  }

  /// Get all temperature records for a litter
  Future<List<Map<String, dynamic>>> getTemperatureRecords({
    required String userId,
    required String litterId,
  }) async {
    try {
      final baseDoc = _getBaseDoc(userId);
      final querySnapshot = await baseDoc
          .collection('litters')
          .doc(litterId)
          .collection('temperature_records')
          .orderBy('dateTime', descending: true)
          .get();
      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Feil ved henting av temperaturmålinger: $e');
    }
  }

  /// Delete temperature record
  Future<void> deleteTemperatureRecord({
    required String userId,
    required String litterId,
    required String recordId,
  }) async {
    try {
      final baseDoc = _getBaseDoc(userId);
      await baseDoc
          .collection('litters')
          .doc(litterId)
          .collection('temperature_records')
          .doc(recordId)
          .delete();
    } catch (e) {
      throw Exception('Feil ved sletting av temperaturmåling: $e');
    }
  }

  // ============ PURCHASE CONTRACTS ============

  /// Save purchase contract to Firestore
  Future<void> savePurchaseContract({
    required String userId,
    required String contractId,
    required Map<String, dynamic> contractData,
  }) async {
    try {
      final baseDoc = _getBaseDoc(userId);
      await baseDoc
          .collection('contracts')
          .doc(contractId)
          .set(contractData, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Feil ved lagring av kontrakt: $e');
    }
  }

  /// Get all purchase contracts for user
  Future<List<Map<String, dynamic>>> getPurchaseContracts(String userId) async {
    try {
      final baseDoc = _getBaseDoc(userId);
      final querySnapshot = await baseDoc.collection('contracts').get();
      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Feil ved henting av kontrakter: $e');
    }
  }

  /// Delete purchase contract
  Future<void> deletePurchaseContract({
    required String userId,
    required String contractId,
  }) async {
    try {
      final baseDoc = _getBaseDoc(userId);
      await baseDoc.collection('contracts').doc(contractId).delete();
    } catch (e) {
      throw Exception('Feil ved sletting av kontrakt: $e');
    }
  }

  // ============ WEIGHT LOGS ============

  /// Save weight log to Firestore
  Future<void> saveWeightLog({
    required String userId,
    required String litterId,
    required String puppyId,
    required String logId,
    required Map<String, dynamic> logData,
  }) async {
    try {
      final baseDoc = _getBaseDoc(userId);
      await baseDoc
          .collection('litters')
          .doc(litterId)
          .collection('puppies')
          .doc(puppyId)
          .collection('weight_logs')
          .doc(logId)
          .set(logData, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Feil ved lagring av vektmåling: $e');
    }
  }

  /// Get all weight logs for a puppy
  Future<List<Map<String, dynamic>>> getWeightLogs({
    required String userId,
    required String litterId,
    required String puppyId,
  }) async {
    try {
      final baseDoc = _getBaseDoc(userId);
      final querySnapshot = await baseDoc
          .collection('litters')
          .doc(litterId)
          .collection('puppies')
          .doc(puppyId)
          .collection('weight_logs')
          .orderBy('date', descending: true)
          .get();
      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Feil ved henting av vektmålinger: $e');
    }
  }

  /// Delete weight log
  Future<void> deleteWeightLog({
    required String userId,
    required String litterId,
    required String puppyId,
    required String logId,
  }) async {
    try {
      final baseDoc = _getBaseDoc(userId);
      await baseDoc
          .collection('litters')
          .doc(litterId)
          .collection('puppies')
          .doc(puppyId)
          .collection('weight_logs')
          .doc(logId)
          .delete();
    } catch (e) {
      throw Exception('Feil ved sletting av vektmåling: $e');
    }
  }

  /// Get real-time updates for dogs
  Stream<List<Map<String, dynamic>>> dogsStream(String userId) {
    final baseDoc = _getBaseDoc(userId);
    return baseDoc
        .collection('dogs')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  /// Get real-time updates for litters
  Stream<List<Map<String, dynamic>>> littersStream(String userId) {
    final baseDoc = _getBaseDoc(userId);
    return baseDoc
        .collection('litters')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  /// Save progesterone measurement to Firestore
  Future<void> saveProgesteroneMeasurement({
    required String userId,
    required String dogId,
    required String measurementId,
    required Map<String, dynamic> measurementData,
  }) async {
    try {
      final baseDoc = _getBaseDoc(userId);
      await baseDoc
          .collection('dogs')
          .doc(dogId)
          .collection('progesterone_measurements')
          .doc(measurementId)
          .set(measurementData, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Feil ved lagring av progesteronmåling: $e');
    }
  }

  /// Get all progesterone measurements for a dog
  Future<List<Map<String, dynamic>>> getProgesteroneMeasurements({
    required String userId,
    required String dogId,
  }) async {
    try {
      final baseDoc = _getBaseDoc(userId);
      final querySnapshot = await baseDoc
          .collection('dogs')
          .doc(dogId)
          .collection('progesterone_measurements')
          .orderBy('dateMeasured', descending: true)
          .get();
      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Feil ved henting av progesteronmålinger: $e');
    }
  }

  /// Delete progesterone measurement
  Future<void> deleteProgesteroneMeasurement({
    required String userId,
    required String dogId,
    required String measurementId,
  }) async {
    try {
      final baseDoc = _getBaseDoc(userId);
      await baseDoc
          .collection('dogs')
          .doc(dogId)
          .collection('progesterone_measurements')
          .doc(measurementId)
          .delete();
    } catch (e) {
      throw Exception('Feil ved sletting av progesteronmåling: $e');
    }
  }

  // ============ HEAT CYCLES ============

  /// Save heat cycle to Firestore
  Future<void> saveHeatCycle({
    required String userId,
    required String dogId,
    required String heatCycleId,
    required Map<String, dynamic> heatCycleData,
  }) async {
    try {
      final baseDoc = _getBaseDoc(userId);
      await baseDoc
          .collection('dogs')
          .doc(dogId)
          .collection('heat_cycles')
          .doc(heatCycleId)
          .set(heatCycleData, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Feil ved lagring av løpetidsdato: $e');
    }
  }

  /// Get all heat cycles for a dog
  Future<List<Map<String, dynamic>>> getHeatCycles({
    required String userId,
    required String dogId,
  }) async {
    try {
      final baseDoc = _getBaseDoc(userId);
      final querySnapshot = await baseDoc
          .collection('dogs')
          .doc(dogId)
          .collection('heat_cycles')
          .orderBy('date', descending: true)
          .get();
      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Feil ved henting av løpetidsdatoer: $e');
    }
  }

  /// Delete heat cycle
  Future<void> deleteHeatCycle({
    required String userId,
    required String dogId,
    required String heatCycleId,
  }) async {
    try {
      final baseDoc = _getBaseDoc(userId);
      await baseDoc
          .collection('dogs')
          .doc(dogId)
          .collection('heat_cycles')
          .doc(heatCycleId)
          .delete();
    } catch (e) {
      throw Exception('Feil ved sletting av løpetidsdato: $e');
    }
  }

  /// Save show result to Firestore
  Future<void> saveShowResult({
    required String userId,
    required String showResultId,
    required Map<String, dynamic> showResultData,
  }) async {
    try {
      final baseDoc = _getBaseDoc(userId);
      await baseDoc
          .collection('show_results')
          .doc(showResultId)
          .set(showResultData, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Feil ved lagring av utstillingsresultat: $e');
    }
  }

  /// Get all show results for user
  Future<List<Map<String, dynamic>>> getShowResults(String userId) async {
    try {
      final baseDoc = _getBaseDoc(userId);
      final querySnapshot = await baseDoc
          .collection('show_results')
          .orderBy('date', descending: true)
          .get();
      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Feil ved henting av utstillingsresultater: $e');
    }
  }

  /// Delete show result
  Future<void> deleteShowResult({
    required String userId,
    required String showResultId,
  }) async {
    try {
      final baseDoc = _getBaseDoc(userId);
      await baseDoc.collection('show_results').doc(showResultId).delete();
    } catch (e) {
      throw Exception('Feil ved sletting av utstillingsresultat: $e');
    }
  }

  /// Static helper to sync show result
  static Future<void> syncShowResult(String userId, dynamic showResult) async {
    await CloudSyncService().saveShowResult(
      userId: userId,
      showResultId: showResult.id,
      showResultData: showResult.toJson(),
    );
  }

  /// Static helper to delete show result
  static Future<void> removeShowResult(
    String userId,
    String showResultId,
  ) async {
    await CloudSyncService().deleteShowResult(
      userId: userId,
      showResultId: showResultId,
    );
  }

  // ============ VET VISITS ============

  /// Save vet visit to Firestore
  Future<void> saveVetVisit({
    required String userId,
    required String dogId,
    required String visitId,
    required Map<String, dynamic> visitData,
  }) async {
    try {
      final baseDoc = _getBaseDoc(userId);
      await baseDoc
          .collection('dogs')
          .doc(dogId)
          .collection('vet_visits')
          .doc(visitId)
          .set(visitData, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Feil ved lagring av veterinærbesøk: $e');
    }
  }

  /// Get all vet visits for a dog
  Future<List<Map<String, dynamic>>> getVetVisits({
    required String userId,
    required String dogId,
  }) async {
    try {
      final baseDoc = _getBaseDoc(userId);
      final querySnapshot = await baseDoc
          .collection('dogs')
          .doc(dogId)
          .collection('vet_visits')
          .orderBy('visitDate', descending: true)
          .get();
      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Feil ved henting av veterinærbesøk: $e');
    }
  }

  /// Delete vet visit
  Future<void> deleteVetVisit({
    required String userId,
    required String dogId,
    required String visitId,
  }) async {
    try {
      final baseDoc = _getBaseDoc(userId);
      await baseDoc
          .collection('dogs')
          .doc(dogId)
          .collection('vet_visits')
          .doc(visitId)
          .delete();
    } catch (e) {
      throw Exception('Feil ved sletting av veterinærbesøk: $e');
    }
  }

  // ============ MEDICAL TREATMENTS ============

  /// Save medical treatment to Firestore
  Future<void> saveMedicalTreatment({
    required String userId,
    required String dogId,
    required String treatmentId,
    required Map<String, dynamic> treatmentData,
  }) async {
    try {
      final baseDoc = _getBaseDoc(userId);
      await baseDoc
          .collection('dogs')
          .doc(dogId)
          .collection('medical_treatments')
          .doc(treatmentId)
          .set(treatmentData, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Feil ved lagring av behandling: $e');
    }
  }

  /// Get all medical treatments for a dog
  Future<List<Map<String, dynamic>>> getMedicalTreatments({
    required String userId,
    required String dogId,
  }) async {
    try {
      final baseDoc = _getBaseDoc(userId);
      final querySnapshot = await baseDoc
          .collection('dogs')
          .doc(dogId)
          .collection('medical_treatments')
          .orderBy('dateGiven', descending: true)
          .get();
      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Feil ved henting av behandlinger: $e');
    }
  }

  /// Delete medical treatment
  Future<void> deleteMedicalTreatment({
    required String userId,
    required String dogId,
    required String treatmentId,
  }) async {
    try {
      final baseDoc = _getBaseDoc(userId);
      await baseDoc
          .collection('dogs')
          .doc(dogId)
          .collection('medical_treatments')
          .doc(treatmentId)
          .delete();
    } catch (e) {
      throw Exception('Feil ved sletting av behandling: $e');
    }
  }

  // ============ DNA TESTS ============

  /// Save DNA test to Firestore
  Future<void> saveDnaTest({
    required String userId,
    required String dogId,
    required String testId,
    required Map<String, dynamic> testData,
  }) async {
    try {
      final baseDoc = _getBaseDoc(userId);
      await baseDoc
          .collection('dogs')
          .doc(dogId)
          .collection('dna_tests')
          .doc(testId)
          .set(testData, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Feil ved lagring av DNA-test: $e');
    }
  }

  /// Get all DNA tests for a dog
  Future<List<Map<String, dynamic>>> getDnaTests({
    required String userId,
    required String dogId,
  }) async {
    try {
      final baseDoc = _getBaseDoc(userId);
      final querySnapshot = await baseDoc
          .collection('dogs')
          .doc(dogId)
          .collection('dna_tests')
          .orderBy('testDate', descending: true)
          .get();
      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Feil ved henting av DNA-tester: $e');
    }
  }

  /// Delete DNA test
  Future<void> deleteDnaTest({
    required String userId,
    required String dogId,
    required String testId,
  }) async {
    try {
      final baseDoc = _getBaseDoc(userId);
      await baseDoc
          .collection('dogs')
          .doc(dogId)
          .collection('dna_tests')
          .doc(testId)
          .delete();
    } catch (e) {
      throw Exception('Feil ved sletting av DNA-test: $e');
    }
  }

  // ============ WEIGHT RECORDS ============

  /// Save weight record to Firestore
  Future<void> saveWeightRecord({
    required String userId,
    required String dogId,
    required String recordId,
    required Map<String, dynamic> recordData,
  }) async {
    try {
      final baseDoc = _getBaseDoc(userId);
      await baseDoc
          .collection('dogs')
          .doc(dogId)
          .collection('weight_records')
          .doc(recordId)
          .set(recordData, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Feil ved lagring av vektregistrering: $e');
    }
  }

  /// Get all weight records for a dog
  Future<List<Map<String, dynamic>>> getWeightRecords({
    required String userId,
    required String dogId,
  }) async {
    try {
      final baseDoc = _getBaseDoc(userId);
      final querySnapshot = await baseDoc
          .collection('dogs')
          .doc(dogId)
          .collection('weight_records')
          .orderBy('date', descending: true)
          .get();
      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Feil ved henting av vektregistreringer: $e');
    }
  }

  /// Delete weight record
  Future<void> deleteWeightRecord({
    required String userId,
    required String dogId,
    required String recordId,
  }) async {
    try {
      final baseDoc = _getBaseDoc(userId);
      await baseDoc
          .collection('dogs')
          .doc(dogId)
          .collection('weight_records')
          .doc(recordId)
          .delete();
    } catch (e) {
      throw Exception('Feil ved sletting av vektregistrering: $e');
    }
  }

  /// Sync delivery checklist to cloud
  Future<void> syncDeliveryChecklist(dynamic checklist, String userId) async {
    try {
      final baseDoc = _getBaseDoc(userId);
      await baseDoc
          .collection('delivery_checklists')
          .doc(checklist.id)
          .set(checklist.toJson(), SetOptions(merge: true));
    } catch (e) {
      AppLogger.debug('Error syncing delivery checklist: $e');
    }
  }

  /// Get delivery checklist from cloud
  Future<Map<String, dynamic>?> getDeliveryChecklist({
    required String userId,
    required String puppyId,
  }) async {
    try {
      final baseDoc = _getBaseDoc(userId);
      final querySnapshot = await baseDoc
          .collection('delivery_checklists')
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
      final baseDoc = _getBaseDoc(userId);
      final querySnapshot = await baseDoc.collection('delivery_checklists').get();
      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      AppLogger.debug('Error getting all delivery checklists: $e');
      return [];
    }
  }

  // ============ TREATMENT PLANS ============

  /// Save treatment plan to Firestore
  Future<void> saveTreatmentPlan({
    required String userId,
    required String treatmentPlanId,
    required Map<String, dynamic> treatmentPlanData,
  }) async {
    try {
      final baseDoc = _getBaseDoc(userId);
      await baseDoc
          .collection('treatment_plans')
          .doc(treatmentPlanId)
          .set(treatmentPlanData, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Feil ved lagring av behandlingsplan: $e');
    }
  }

  /// Get all treatment plans for user
  Future<List<Map<String, dynamic>>> getTreatmentPlans(String userId) async {
    try {
      final baseDoc = _getBaseDoc(userId);
      final querySnapshot = await baseDoc.collection('treatment_plans').get();
      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Feil ved henting av behandlingsplaner: $e');
    }
  }

  /// Delete treatment plan
  Future<void> deleteTreatmentPlan({
    required String userId,
    required String treatmentPlanId,
  }) async {
    try {
      final baseDoc = _getBaseDoc(userId);
      await baseDoc.collection('treatment_plans').doc(treatmentPlanId).delete();
    } catch (e) {
      throw Exception('Feil ved sletting av behandlingsplan: $e');
    }
  }

  // ============ BREEDING CONTRACTS ============

  /// Save breeding contract to Firestore
  Future<void> saveBreedingContract({
    required String userId,
    required String contractId,
    required Map<String, dynamic> contractData,
  }) async {
    try {
      final baseDoc = _getBaseDoc(userId);
      await baseDoc
          .collection('breeding_contracts')
          .doc(contractId)
          .set(contractData, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Feil ved lagring av avlskontrakt: $e');
    }
  }

  /// Get all breeding contracts for user
  Future<List<Map<String, dynamic>>> getBreedingContracts(String userId) async {
    try {
      final baseDoc = _getBaseDoc(userId);
      final querySnapshot = await baseDoc.collection('breeding_contracts').get();
      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Feil ved henting av avlskontrakter: $e');
    }
  }

  /// Delete breeding contract
  Future<void> deleteBreedingContract({
    required String userId,
    required String contractId,
  }) async {
    try {
      final baseDoc = _getBaseDoc(userId);
      await baseDoc.collection('breeding_contracts').doc(contractId).delete();
    } catch (e) {
      throw Exception('Feil ved sletting av avlskontrakt: $e');
    }
  }

  // ============ CO-OWNERSHIP CONTRACTS ============

  /// Save co-ownership contract to Firestore
  Future<void> saveCoOwnershipContract({
    required String userId,
    required String contractId,
    required Map<String, dynamic> contractData,
  }) async {
    try {
      final baseDoc = _getBaseDoc(userId);
      await baseDoc
          .collection('co_ownership_contracts')
          .doc(contractId)
          .set(contractData, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Feil ved lagring av medeieravtale: $e');
    }
  }

  /// Get all co-ownership contracts for user
  Future<List<Map<String, dynamic>>> getCoOwnershipContracts(String userId) async {
    try {
      final baseDoc = _getBaseDoc(userId);
      final querySnapshot = await baseDoc.collection('co_ownership_contracts').get();
      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Feil ved henting av medeieravtaler: $e');
    }
  }

  /// Delete co-ownership contract
  Future<void> deleteCoOwnershipContract({
    required String userId,
    required String contractId,
  }) async {
    try {
      final baseDoc = _getBaseDoc(userId);
      await baseDoc.collection('co_ownership_contracts').doc(contractId).delete();
    } catch (e) {
      throw Exception('Feil ved sletting av medeieravtale: $e');
    }
  }

  // ============ FOSTER CONTRACTS ============

  /// Save foster contract to Firestore
  Future<void> saveFosterContract({
    required String userId,
    required String contractId,
    required Map<String, dynamic> contractData,
  }) async {
    try {
      final baseDoc = _getBaseDoc(userId);
      await baseDoc
          .collection('foster_contracts')
          .doc(contractId)
          .set(contractData, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Feil ved lagring av fôrvertsavtale: $e');
    }
  }

  /// Get all foster contracts for user
  Future<List<Map<String, dynamic>>> getFosterContracts(String userId) async {
    try {
      final baseDoc = _getBaseDoc(userId);
      final querySnapshot = await baseDoc.collection('foster_contracts').get();
      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Feil ved henting av fôrvertsavtaler: $e');
    }
  }

  /// Delete foster contract
  Future<void> deleteFosterContract({
    required String userId,
    required String contractId,
  }) async {
    try {
      final baseDoc = _getBaseDoc(userId);
      await baseDoc.collection('foster_contracts').doc(contractId).delete();
    } catch (e) {
      throw Exception('Feil ved sletting av fôrvertsavtale: $e');
    }
  }

  // ============ RESERVATION CONTRACTS ============

  /// Save reservation contract to Firestore
  Future<void> saveReservationContract({
    required String userId,
    required String contractId,
    required Map<String, dynamic> contractData,
  }) async {
    try {
      final baseDoc = _getBaseDoc(userId);
      await baseDoc
          .collection('reservation_contracts')
          .doc(contractId)
          .set(contractData, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Feil ved lagring av reservasjonsavtale: $e');
    }
  }

  /// Get all reservation contracts for user
  Future<List<Map<String, dynamic>>> getReservationContracts(String userId) async {
    try {
      final baseDoc = _getBaseDoc(userId);
      final querySnapshot = await baseDoc.collection('reservation_contracts').get();
      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Feil ved henting av reservasjonsavtaler: $e');
    }
  }

  /// Delete reservation contract
  Future<void> deleteReservationContract({
    required String userId,
    required String contractId,
  }) async {
    try {
      final baseDoc = _getBaseDoc(userId);
      await baseDoc.collection('reservation_contracts').doc(contractId).delete();
    } catch (e) {
      throw Exception('Feil ved sletting av reservasjonsavtale: $e');
    }
  }
}
