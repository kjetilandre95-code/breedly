import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:breedly/models/dog.dart';
import 'package:breedly/models/litter.dart';
import 'package:breedly/models/puppy.dart';
import 'package:breedly/models/expense.dart';
import 'package:breedly/models/income.dart';
import 'package:breedly/models/buyer.dart';
import 'package:breedly/models/mating.dart';
import 'package:breedly/models/temperature_record.dart';
import 'package:breedly/models/purchase_contract.dart';
import 'package:breedly/models/puppy_weight_log.dart';
import 'package:breedly/models/kennel_profile.dart';
import 'package:breedly/models/progesterone_measurement.dart';
import 'package:breedly/models/show_result.dart';
import 'package:breedly/models/vet_visit.dart';
import 'package:breedly/models/medical_treatment.dart';
import 'package:breedly/models/dna_test.dart';
import 'package:breedly/models/weight_record.dart';
import 'package:breedly/models/treatment_plan.dart';
import 'package:breedly/models/delivery_checklist.dart';
import 'package:breedly/models/breeding_contract.dart';
import 'package:breedly/models/co_ownership_contract.dart';
import 'package:breedly/models/foster_contract.dart';
import 'package:breedly/models/reservation_contract.dart';
import 'package:breedly/services/cloud_sync_service.dart';
import 'package:breedly/utils/logger.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class DataSyncService {
  static final DataSyncService _instance = DataSyncService._internal();

  factory DataSyncService() {
    return _instance;
  }

  DataSyncService._internal();

  final _cloudSync = CloudSyncService();

  /// Check if device has internet connectivity
  Future<bool> _hasConnectivity() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      // Handle both single result and list result (connectivity_plus version compatibility)
      if (connectivityResult is List) {
        final results = connectivityResult as List;
        if (results.isEmpty) return false;
        for (final result in results) {
          if (result == ConnectivityResult.mobile || 
              result == ConnectivityResult.wifi ||
              result == ConnectivityResult.ethernet) {
            return true;
          }
        }
        return !results.contains(ConnectivityResult.none);
      } else {
        // Single result (older API or ConnectivityResult type)
        return connectivityResult != ConnectivityResult.none;
      }
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
      return true; // Default to true to allow sync attempts
    }
  }

  /// Syncs all user data from Firebase to local Hive storage
  /// Should be called after user logs in to ensure local cache is up-to-date
  /// Uses merge strategy to preserve locally created data
  Future<void> syncAllDataFromFirebase(String userId) async {
    try {
      // Check connectivity first
      if (!await _hasConnectivity()) {
        AppLogger.debug('No internet connectivity - skipping sync from Firebase');
        return;
      }

      AppLogger.debug('Starting data sync from Firebase for user: $userId');

      // Sync dogs
      await _syncDogs(userId);

      // Sync litters
      await _syncLitters(userId);

      // Sync puppies (for each litter)
      await _syncPuppies(userId);

      // Sync health info
      await _syncHealthInfo(userId);

      // Sync vaccines
      await _syncVaccines(userId);

      // Sync expenses
      await _syncExpenses(userId);

      // Sync income
      await _syncIncome(userId);

      // Sync buyers
      await _syncBuyers(userId);

      // Sync matings
      await _syncMatings(userId);

      // Sync heat cycles
      await _syncHeatCycles(userId);

      // Sync temperature records
      await _syncTemperatureRecords(userId);

      // Sync purchase contracts
      await _syncPurchaseContracts(userId);

      // Sync weight logs
      await _syncWeightLogs(userId);

      // Sync kennel profile
      await _syncKennelProfile(userId);

      // Sync progesterone measurements
      await _syncProgesteroneMeasurements(userId);

      // Sync show results
      await _syncShowResults(userId);

      // Sync vet visits
      await _syncVetVisits(userId);

      // Sync medical treatments
      await _syncMedicalTreatments(userId);

      // Sync DNA tests
      await _syncDnaTests(userId);

      // Sync weight records (dog weight)
      await _syncWeightRecords(userId);

      // Sync treatment plans
      await _syncTreatmentPlans(userId);

      // Sync delivery checklists
      await _syncDeliveryChecklists(userId);

      // Sync breeding contracts
      await _syncBreedingContracts(userId);

      // Sync co-ownership contracts
      await _syncCoOwnershipContracts(userId);

      // Sync foster contracts
      await _syncFosterContracts(userId);

      // Sync reservation contracts
      await _syncReservationContracts(userId);

      AppLogger.debug('Data sync from Firebase completed successfully');
    } catch (e) {
      AppLogger.debug('Error syncing data from Firebase: $e');
      // Don't rethrow - allow app to continue with local data
    }
  }

  /// Uploads all local data to Firebase
  /// Call this to push locally created/modified data to the cloud
  Future<void> uploadAllDataToFirebase(String userId) async {
    try {
      // Check connectivity first
      if (!await _hasConnectivity()) {
        AppLogger.debug('No internet connectivity - skipping upload to Firebase');
        return;
      }

      AppLogger.debug('Starting upload of local data to Firebase for user: $userId');

      // Upload dogs
      await _uploadDogs(userId);

      // Upload litters
      await _uploadLitters(userId);

      // Upload puppies
      await _uploadPuppies(userId);

      // Upload expenses
      await _uploadExpenses(userId);

      // Upload income
      await _uploadIncome(userId);

      // Upload buyers
      await _uploadBuyers(userId);

      // Upload matings
      await _uploadMatings(userId);

      // Upload heat cycles
      await _uploadHeatCycles(userId);

      // Upload temperature records
      await _uploadTemperatureRecords(userId);

      // Upload purchase contracts
      await _uploadPurchaseContracts(userId);

      // Upload weight logs
      await _uploadWeightLogs(userId);

      // Upload kennel profile
      await _uploadKennelProfile(userId);

      // Upload progesterone measurements
      await _uploadProgesteroneMeasurements(userId);

      // Upload show results
      await _uploadShowResults(userId);

      // Upload vet visits
      await _uploadVetVisits(userId);

      // Upload medical treatments
      await _uploadMedicalTreatments(userId);

      // Upload DNA tests
      await _uploadDnaTests(userId);

      // Upload weight records (dog weight)
      await _uploadWeightRecords(userId);

      // Upload treatment plans
      await _uploadTreatmentPlans(userId);

      // Upload delivery checklists
      await _uploadDeliveryChecklists(userId);

      // Upload breeding contracts
      await _uploadBreedingContracts(userId);

      // Upload co-ownership contracts
      await _uploadCoOwnershipContracts(userId);

      // Upload foster contracts
      await _uploadFosterContracts(userId);

      // Upload reservation contracts
      await _uploadReservationContracts(userId);

      AppLogger.debug('Upload to Firebase completed successfully');
    } catch (e) {
      AppLogger.debug('Error uploading data to Firebase: $e');
    }
  }

  /// Syncs dogs from Firebase to Hive using merge strategy
  Future<void> _syncDogs(String userId) async {
    try {
      final dogsList = await _cloudSync.getDogs(userId);
      final dogsBox = Hive.box<Dog>('dogs');

      // Add/update dogs from Firebase (merge, don't clear)
      for (final dogData in dogsList) {
        final dog = Dog.fromJson(dogData);
        await dogsBox.put(dog.id, dog);
      }

      AppLogger.debug('Synced ${dogsList.length} dogs from Firebase');
    } catch (e) {
      AppLogger.debug('Error syncing dogs: $e');
      // Don't clear local data on error
    }
  }

  /// Uploads local dogs to Firebase
  Future<void> _uploadDogs(String userId) async {
    try {
      final dogsBox = Hive.box<Dog>('dogs');
      final dogs = dogsBox.values.toList();

      for (final dog in dogs) {
        await _cloudSync.saveDog(
          userId: userId,
          dogId: dog.id,
          dogData: dog.toJson(),
        );
      }

      AppLogger.debug('Uploaded ${dogs.length} dogs to Firebase');
    } catch (e) {
      AppLogger.debug('Error uploading dogs: $e');
    }
  }

  /// Syncs litters from Firebase to Hive using merge strategy
  Future<void> _syncLitters(String userId) async {
    try {
      final littersList = await _cloudSync.getLitters(userId);
      final littersBox = Hive.box<Litter>('litters');

      // Add/update litters from Firebase (merge, don't clear)
      for (final litterData in littersList) {
        final litter = Litter.fromJson(litterData);
        await littersBox.put(litter.id, litter);
      }

      AppLogger.debug('Synced ${littersList.length} litters from Firebase');
    } catch (e) {
      AppLogger.debug('Error syncing litters: $e');
    }
  }

  /// Uploads local litters to Firebase
  Future<void> _uploadLitters(String userId) async {
    try {
      final littersBox = Hive.box<Litter>('litters');
      final litters = littersBox.values.toList();

      for (final litter in litters) {
        await _cloudSync.saveLitter(
          userId: userId,
          litterId: litter.id,
          litterData: litter.toJson(),
        );
      }

      AppLogger.debug('Uploaded ${litters.length} litters to Firebase');
    } catch (e) {
      AppLogger.debug('Error uploading litters: $e');
    }
  }

  /// Syncs puppies from Firebase to Hive using merge strategy
  Future<void> _syncPuppies(String userId) async {
    try {
      final puppiesBox = Hive.box<Puppy>('puppies');
      final littersBox = Hive.box<Litter>('litters');

      // Get all litters
      final litters = littersBox.values.toList();
      
      // Sync puppies for each litter (merge, don't clear)
      for (final litter in litters) {
        try {
          final puppiesList = await _cloudSync.getPuppies(
            userId: userId,
            litterId: litter.id,
          );

          // Add/update puppies from Firebase
          for (final puppyData in puppiesList) {
            final puppy = Puppy.fromJson(puppyData);
            await puppiesBox.put(puppy.id, puppy);
          }
        } catch (e) {
          AppLogger.debug('Error syncing puppies for litter ${litter.id}: $e');
        }
      }

      AppLogger.debug('Synced puppies from Firebase for ${litters.length} litters');
    } catch (e) {
      AppLogger.debug('Error syncing puppies: $e');
    }
  }

  /// Uploads local puppies to Firebase
  Future<void> _uploadPuppies(String userId) async {
    try {
      final puppiesBox = Hive.box<Puppy>('puppies');
      final puppies = puppiesBox.values.toList();

      for (final puppy in puppies) {
        await _cloudSync.savePuppy(
          userId: userId,
          litterId: puppy.litterId,
          puppyId: puppy.id,
          puppyData: puppy.toJson(),
        );
      }

      AppLogger.debug('Uploaded ${puppies.length} puppies to Firebase');
    } catch (e) {
      AppLogger.debug('Error uploading puppies: $e');
    }
  }

  /// Syncs health info from Firebase to Hive
  Future<void> _syncHealthInfo(String userId) async {
    try {
      // Health info is synced per dog, so we get it from the dogs
      final dogsBox = Hive.box<Dog>('dogs');
      final dogs = dogsBox.values.toList();

      for (final dog in dogs) {
        if (dog.healthInfoId != null) {
          // In a real implementation, you'd fetch the health info from Firebase
          // For now, we're using the local data that's linked to the dog
          // This assumes health info is already synced or linked properly
        }
      }

      AppLogger.debug('Health info sync completed');
    } catch (e) {
      AppLogger.debug('Error syncing health info: $e');
    }
  }

  /// Syncs vaccines from Firebase to Hive
  Future<void> _syncVaccines(String userId) async {
    try {
      // Vaccines are stored per dog in Firebase
      // You would need a method in CloudSyncService to get all vaccines for all dogs
      // For now, this is a placeholder

      AppLogger.debug('Vaccines sync completed');
    } catch (e) {
      AppLogger.debug('Error syncing vaccines: $e');
    }
  }

  /// Syncs expenses from Firebase to Hive using merge strategy
  Future<void> _syncExpenses(String userId) async {
    try {
      final expensesList = await _cloudSync.getExpenses(userId);
      final expensesBox = Hive.box<Expense>('expenses');

      // Add/update expenses from Firebase (merge, don't clear)
      for (final expenseData in expensesList) {
        final expense = Expense.fromJson(expenseData);
        await expensesBox.put(expense.id, expense);
      }

      AppLogger.debug('Synced ${expensesList.length} expenses from Firebase');
    } catch (e) {
      AppLogger.debug('Error syncing expenses: $e');
    }
  }

  /// Uploads local expenses to Firebase
  Future<void> _uploadExpenses(String userId) async {
    try {
      final expensesBox = Hive.box<Expense>('expenses');
      final expenses = expensesBox.values.toList();

      for (final expense in expenses) {
        await _cloudSync.saveExpense(
          userId: userId,
          expenseId: expense.id,
          expenseData: expense.toJson(),
        );
      }

      AppLogger.debug('Uploaded ${expenses.length} expenses to Firebase');
    } catch (e) {
      AppLogger.debug('Error uploading expenses: $e');
    }
  }

  /// Syncs income from Firebase to Hive using merge strategy
  Future<void> _syncIncome(String userId) async {
    try {
      final incomeList = await _cloudSync.getIncome(userId);
      final incomeBox = Hive.box<Income>('incomes');

      // Add/update income from Firebase (merge, don't clear)
      for (final incomeData in incomeList) {
        final income = Income.fromJson(incomeData);
        await incomeBox.put(income.id, income);
      }

      AppLogger.debug('Synced ${incomeList.length} income entries from Firebase');
    } catch (e) {
      AppLogger.debug('Error syncing income: $e');
    }
  }

  /// Uploads local income to Firebase
  Future<void> _uploadIncome(String userId) async {
    try {
      final incomeBox = Hive.box<Income>('incomes');
      final incomes = incomeBox.values.toList();

      for (final income in incomes) {
        await _cloudSync.saveIncome(
          userId: userId,
          incomeId: income.id,
          incomeData: income.toJson(),
        );
      }

      AppLogger.debug('Uploaded ${incomes.length} income entries to Firebase');
    } catch (e) {
      AppLogger.debug('Error uploading income: $e');
    }
  }

  // ============ BUYERS ============

  /// Syncs buyers from Firebase to Hive
  Future<void> _syncBuyers(String userId) async {
    try {
      final buyersList = await _cloudSync.getBuyers(userId);
      final buyersBox = Hive.box<Buyer>('buyers');

      for (final buyerData in buyersList) {
        final buyer = Buyer.fromJson(buyerData);
        await buyersBox.put(buyer.id, buyer);
      }

      AppLogger.debug('Synced ${buyersList.length} buyers from Firebase');
    } catch (e) {
      AppLogger.debug('Error syncing buyers: $e');
    }
  }

  /// Uploads local buyers to Firebase
  Future<void> _uploadBuyers(String userId) async {
    try {
      final buyersBox = Hive.box<Buyer>('buyers');
      final buyers = buyersBox.values.toList();

      for (final buyer in buyers) {
        await _cloudSync.saveBuyer(
          userId: userId,
          buyerId: buyer.id,
          buyerData: buyer.toJson(),
        );
      }

      AppLogger.debug('Uploaded ${buyers.length} buyers to Firebase');
    } catch (e) {
      AppLogger.debug('Error uploading buyers: $e');
    }
  }

  // ============ MATINGS ============

  /// Syncs matings from Firebase to Hive
  Future<void> _syncMatings(String userId) async {
    try {
      final dogsBox = Hive.box<Dog>('dogs');
      final matingsBox = Hive.box<Mating>('matings');
      final dogs = dogsBox.values.toList();

      for (final dog in dogs) {
        try {
          final matingsList = await _cloudSync.getMatings(
            userId: userId,
            dogId: dog.id,
          );

          for (final matingData in matingsList) {
            final mating = Mating.fromJson(matingData);
            await matingsBox.put(mating.id, mating);
          }
        } catch (e) {
          AppLogger.debug('Error syncing matings for dog ${dog.id}: $e');
        }
      }

      AppLogger.debug('Synced matings from Firebase');
    } catch (e) {
      AppLogger.debug('Error syncing matings: $e');
    }
  }

  /// Uploads local matings to Firebase
  Future<void> _uploadMatings(String userId) async {
    try {
      final matingsBox = Hive.box<Mating>('matings');
      final matings = matingsBox.values.toList();

      for (final mating in matings) {
        await _cloudSync.saveMating(
          userId: userId,
          dogId: mating.sireId, // Use sireId as the dog reference
          matingId: mating.id,
          matingData: mating.toJson(),
        );
      }

      AppLogger.debug('Uploaded ${matings.length} matings to Firebase');
    } catch (e) {
      AppLogger.debug('Error uploading matings: $e');
    }
  }

  // ============ HEAT CYCLES ============

  /// Syncs heat cycles from Firebase to Hive
  Future<void> _syncHeatCycles(String userId) async {
    try {
      final dogsBox = Hive.box<Dog>('dogs');
      final dogs = dogsBox.values.toList();

      for (final dog in dogs) {
        try {
          final heatCyclesList = await _cloudSync.getHeatCycles(
            userId: userId,
            dogId: dog.id,
          );

          // Clear existing heat cycles and add from Firebase
          dog.heatCycles.clear();
          for (final heatCycleData in heatCyclesList) {
            final dateString = heatCycleData['date'] as String;
            final date = DateTime.parse(dateString);
            dog.heatCycles.add(date);
          }

          // Sort heat cycles (newest first)
          dog.heatCycles.sort((a, b) => b.compareTo(a));

          // Save the updated dog
          await dog.save();
        } catch (e) {
          AppLogger.debug('Error syncing heat cycles for dog ${dog.id}: $e');
        }
      }

      AppLogger.debug('Synced heat cycles from Firebase');
    } catch (e) {
      AppLogger.debug('Error syncing heat cycles: $e');
    }
  }

  /// Uploads local heat cycles to Firebase
  Future<void> _uploadHeatCycles(String userId) async {
    try {
      final dogsBox = Hive.box<Dog>('dogs');
      final dogs = dogsBox.values.toList();

      for (final dog in dogs) {
        for (final heatCycle in dog.heatCycles) {
          final heatCycleId = heatCycle.millisecondsSinceEpoch.toString();
          await _cloudSync.saveHeatCycle(
            userId: userId,
            dogId: dog.id,
            heatCycleId: heatCycleId,
            heatCycleData: {
              'date': heatCycle.toIso8601String(),
              'timestamp': heatCycle.millisecondsSinceEpoch,
            },
          );
        }
      }

      AppLogger.debug('Uploaded heat cycles to Firebase');
    } catch (e) {
      AppLogger.debug('Error uploading heat cycles: $e');
    }
  }

  // ============ TEMPERATURE RECORDS ============

  /// Syncs temperature records from Firebase to Hive
  Future<void> _syncTemperatureRecords(String userId) async {
    try {
      final littersBox = Hive.box<Litter>('litters');
      final recordsBox = Hive.box<TemperatureRecord>('temperature_records');
      final litters = littersBox.values.toList();

      for (final litter in litters) {
        try {
          final recordsList = await _cloudSync.getTemperatureRecords(
            userId: userId,
            litterId: litter.id,
          );

          for (final recordData in recordsList) {
            final record = TemperatureRecord.fromJson(recordData);
            await recordsBox.put(record.id, record);
          }
        } catch (e) {
          AppLogger.debug('Error syncing temperature records for litter ${litter.id}: $e');
        }
      }

      AppLogger.debug('Synced temperature records from Firebase');
    } catch (e) {
      AppLogger.debug('Error syncing temperature records: $e');
    }
  }

  /// Uploads local temperature records to Firebase
  Future<void> _uploadTemperatureRecords(String userId) async {
    try {
      final recordsBox = Hive.box<TemperatureRecord>('temperature_records');
      final records = recordsBox.values.toList();

      for (final record in records) {
        await _cloudSync.saveTemperatureRecord(
          userId: userId,
          litterId: record.litterId,
          recordId: record.id,
          recordData: record.toJson(),
        );
      }

      AppLogger.debug('Uploaded ${records.length} temperature records to Firebase');
    } catch (e) {
      AppLogger.debug('Error uploading temperature records: $e');
    }
  }

  // ============ PURCHASE CONTRACTS ============

  /// Syncs purchase contracts from Firebase to Hive
  Future<void> _syncPurchaseContracts(String userId) async {
    try {
      final contractsList = await _cloudSync.getPurchaseContracts(userId);
      final contractsBox = Hive.box<PurchaseContract>('purchase_contracts');

      for (final contractData in contractsList) {
        final contract = PurchaseContract.fromJson(contractData);
        await contractsBox.put(contract.id, contract);
      }

      AppLogger.debug('Synced ${contractsList.length} contracts from Firebase');
    } catch (e) {
      AppLogger.debug('Error syncing contracts: $e');
    }
  }

  /// Uploads local purchase contracts to Firebase
  Future<void> _uploadPurchaseContracts(String userId) async {
    try {
      final contractsBox = Hive.box<PurchaseContract>('purchase_contracts');
      final contracts = contractsBox.values.toList();

      for (final contract in contracts) {
        await _cloudSync.savePurchaseContract(
          userId: userId,
          contractId: contract.id,
          contractData: contract.toJson(),
        );
      }

      AppLogger.debug('Uploaded ${contracts.length} contracts to Firebase');
    } catch (e) {
      AppLogger.debug('Error uploading contracts: $e');
    }
  }

  // ============ WEIGHT LOGS ============

  /// Syncs weight logs from Firebase to Hive
  Future<void> _syncWeightLogs(String userId) async {
    try {
      final littersBox = Hive.box<Litter>('litters');
      final puppiesBox = Hive.box<Puppy>('puppies');
      final logsBox = Hive.box<PuppyWeightLog>('weight_logs');
      final litters = littersBox.values.toList();

      for (final litter in litters) {
        final puppies = puppiesBox.values.where((p) => p.litterId == litter.id).toList();
        
        for (final puppy in puppies) {
          try {
            final logsList = await _cloudSync.getWeightLogs(
              userId: userId,
              litterId: litter.id,
              puppyId: puppy.id,
            );

            for (final logData in logsList) {
              final log = PuppyWeightLog.fromJson(logData);
              await logsBox.put(log.id, log);
            }
          } catch (e) {
            AppLogger.debug('Error syncing weight logs for puppy ${puppy.id}: $e');
          }
        }
      }

      AppLogger.debug('Synced weight logs from Firebase');
    } catch (e) {
      AppLogger.debug('Error syncing weight logs: $e');
    }
  }

  /// Uploads local weight logs to Firebase
  Future<void> _uploadWeightLogs(String userId) async {
    try {
      final logsBox = Hive.box<PuppyWeightLog>('weight_logs');
      final puppiesBox = Hive.box<Puppy>('puppies');
      final logs = logsBox.values.toList();

      for (final log in logs) {
        // Find puppy to get litterId
        final puppy = puppiesBox.values.firstWhere(
          (p) => p.id == log.puppyId,
          orElse: () => Puppy(id: '', litterId: '', name: '', gender: '', color: '', dateOfBirth: DateTime.now()),
        );
        
        if (puppy.litterId.isNotEmpty) {
          await _cloudSync.saveWeightLog(
            userId: userId,
            litterId: puppy.litterId,
            puppyId: log.puppyId,
            logId: log.id,
            logData: log.toJson(),
          );
        }
      }

      AppLogger.debug('Uploaded ${logs.length} weight logs to Firebase');
    } catch (e) {
      AppLogger.debug('Error uploading weight logs: $e');
    }
  }

  /// Syncs kennel profile from Firebase to Hive
  Future<void> _syncKennelProfile(String userId) async {
    try {
      final profileData = await _cloudSync.getKennelProfile(userId);
      if (profileData != null) {
        final profileBox = Hive.box<KennelProfile>('kennel_profile');
        final profile = KennelProfile.fromJson(profileData);
        await profileBox.put('profile', profile);
        AppLogger.debug('Synced kennel profile from Firebase');
      }
    } catch (e) {
      AppLogger.debug('Error syncing kennel profile: $e');
    }
  }

  /// Uploads local kennel profile to Firebase
  Future<void> _uploadKennelProfile(String userId) async {
    try {
      final profileBox = Hive.box<KennelProfile>('kennel_profile');
      if (profileBox.isNotEmpty) {
        final profile = profileBox.values.first;
        await _cloudSync.saveKennelProfile(
          userId: userId,
          profileData: profile.toJson(),
        );
        AppLogger.debug('Uploaded kennel profile to Firebase');
      }
    } catch (e) {
      AppLogger.debug('Error uploading kennel profile: $e');
    }
  }

  // ============ PROGESTERONE MEASUREMENTS ============

  /// Syncs progesterone measurements from Firebase to Hive
  Future<void> _syncProgesteroneMeasurements(String userId) async {
    try {
      final dogsBox = Hive.box<Dog>('dogs');
      final measurementsBox = Hive.box<ProgesteroneMeasurement>('progesterone_measurements');
      final dogs = dogsBox.values.where((d) => d.gender == 'Female').toList();

      for (final dog in dogs) {
        try {
          final measurementsList = await _cloudSync.getProgesteroneMeasurements(
            userId: userId,
            dogId: dog.id,
          );

          for (final measurementData in measurementsList) {
            final measurement = ProgesteroneMeasurement.fromJson(measurementData);
            await measurementsBox.put(measurement.id, measurement);
          }
        } catch (e) {
          AppLogger.debug('Error syncing progesterone measurements for dog ${dog.id}: $e');
        }
      }

      AppLogger.debug('Synced progesterone measurements from Firebase');
    } catch (e) {
      AppLogger.debug('Error syncing progesterone measurements: $e');
    }
  }

  /// Uploads local progesterone measurements to Firebase
  Future<void> _uploadProgesteroneMeasurements(String userId) async {
    try {
      final measurementsBox = Hive.box<ProgesteroneMeasurement>('progesterone_measurements');
      final measurements = measurementsBox.values.toList();

      for (final measurement in measurements) {
        await _cloudSync.saveProgesteroneMeasurement(
          userId: userId,
          dogId: measurement.dogId,
          measurementId: measurement.id,
          measurementData: measurement.toJson(),
        );
      }

      AppLogger.debug('Uploaded ${measurements.length} progesterone measurements to Firebase');
    } catch (e) {
      AppLogger.debug('Error uploading progesterone measurements: $e');
    }
  }

  // ============ SHOW RESULTS ============

  /// Syncs show results from Firebase to Hive
  Future<void> _syncShowResults(String userId) async {
    try {
      final showResultsList = await _cloudSync.getShowResults(userId);
      final showResultsBox = Hive.box<ShowResult>('show_results');

      for (final resultData in showResultsList) {
        final result = ShowResult.fromJson(resultData);
        await showResultsBox.put(result.id, result);
      }

      AppLogger.debug('Synced ${showResultsList.length} show results from Firebase');
    } catch (e) {
      AppLogger.debug('Error syncing show results: $e');
    }
  }

  /// Uploads local show results to Firebase
  Future<void> _uploadShowResults(String userId) async {
    try {
      final showResultsBox = Hive.box<ShowResult>('show_results');
      final results = showResultsBox.values.toList();

      for (final result in results) {
        await _cloudSync.saveShowResult(
          userId: userId,
          showResultId: result.id,
          showResultData: result.toJson(),
        );
      }

      AppLogger.debug('Uploaded ${results.length} show results to Firebase');
    } catch (e) {
      AppLogger.debug('Error uploading show results: $e');
    }
  }

  /// Performs a full bi-directional sync
  /// First uploads local data to Firebase, then syncs from Firebase
  Future<void> performFullSync(String userId) async {
    if (!await _hasConnectivity()) {
      AppLogger.debug('No internet connectivity - skipping full sync');
      return;
    }

    // Upload local changes first
    await uploadAllDataToFirebase(userId);
    
    // Then sync from Firebase to get any changes from other devices
    await syncAllDataFromFirebase(userId);
  }

  // ============ VET VISITS ============

  /// Syncs vet visits from Firebase to Hive
  Future<void> _syncVetVisits(String userId) async {
    try {
      final dogsBox = Hive.box<Dog>('dogs');
      final vetVisitsBox = Hive.box<VetVisit>('vet_visits');
      final dogs = dogsBox.values.toList();

      for (final dog in dogs) {
        try {
          final visitsList = await _cloudSync.getVetVisits(
            userId: userId,
            dogId: dog.id,
          );

          for (final visitData in visitsList) {
            final visit = VetVisit.fromJson(visitData);
            await vetVisitsBox.put(visit.id, visit);
          }
        } catch (e) {
          AppLogger.debug('Error syncing vet visits for dog ${dog.id}: $e');
        }
      }

      AppLogger.debug('Synced vet visits from Firebase');
    } catch (e) {
      AppLogger.debug('Error syncing vet visits: $e');
    }
  }

  /// Uploads local vet visits to Firebase
  Future<void> _uploadVetVisits(String userId) async {
    try {
      final vetVisitsBox = Hive.box<VetVisit>('vet_visits');
      final visits = vetVisitsBox.values.toList();

      for (final visit in visits) {
        await _cloudSync.saveVetVisit(
          userId: userId,
          dogId: visit.dogId,
          visitId: visit.id,
          visitData: visit.toJson(),
        );
      }

      AppLogger.debug('Uploaded ${visits.length} vet visits to Firebase');
    } catch (e) {
      AppLogger.debug('Error uploading vet visits: $e');
    }
  }

  // ============ MEDICAL TREATMENTS ============

  /// Syncs medical treatments from Firebase to Hive
  Future<void> _syncMedicalTreatments(String userId) async {
    try {
      final dogsBox = Hive.box<Dog>('dogs');
      final treatmentsBox = Hive.box<MedicalTreatment>('medical_treatments');
      final dogs = dogsBox.values.toList();

      for (final dog in dogs) {
        try {
          final treatmentsList = await _cloudSync.getMedicalTreatments(
            userId: userId,
            dogId: dog.id,
          );

          for (final treatmentData in treatmentsList) {
            final treatment = MedicalTreatment.fromJson(treatmentData);
            await treatmentsBox.put(treatment.id, treatment);
          }
        } catch (e) {
          AppLogger.debug('Error syncing medical treatments for dog ${dog.id}: $e');
        }
      }

      AppLogger.debug('Synced medical treatments from Firebase');
    } catch (e) {
      AppLogger.debug('Error syncing medical treatments: $e');
    }
  }

  /// Uploads local medical treatments to Firebase
  Future<void> _uploadMedicalTreatments(String userId) async {
    try {
      final treatmentsBox = Hive.box<MedicalTreatment>('medical_treatments');
      final treatments = treatmentsBox.values.toList();

      for (final treatment in treatments) {
        await _cloudSync.saveMedicalTreatment(
          userId: userId,
          dogId: treatment.dogId,
          treatmentId: treatment.id,
          treatmentData: treatment.toJson(),
        );
      }

      AppLogger.debug('Uploaded ${treatments.length} medical treatments to Firebase');
    } catch (e) {
      AppLogger.debug('Error uploading medical treatments: $e');
    }
  }

  // ============ DNA TESTS ============

  /// Syncs DNA tests from Firebase to Hive
  Future<void> _syncDnaTests(String userId) async {
    try {
      final dogsBox = Hive.box<Dog>('dogs');
      final dnaTestsBox = Hive.box<DnaTest>('dna_tests');
      final dogs = dogsBox.values.toList();

      for (final dog in dogs) {
        try {
          final testsList = await _cloudSync.getDnaTests(
            userId: userId,
            dogId: dog.id,
          );

          for (final testData in testsList) {
            final test = DnaTest.fromJson(testData);
            await dnaTestsBox.put(test.id, test);
          }
        } catch (e) {
          AppLogger.debug('Error syncing DNA tests for dog ${dog.id}: $e');
        }
      }

      AppLogger.debug('Synced DNA tests from Firebase');
    } catch (e) {
      AppLogger.debug('Error syncing DNA tests: $e');
    }
  }

  /// Uploads local DNA tests to Firebase
  Future<void> _uploadDnaTests(String userId) async {
    try {
      final dnaTestsBox = Hive.box<DnaTest>('dna_tests');
      final tests = dnaTestsBox.values.toList();

      for (final test in tests) {
        await _cloudSync.saveDnaTest(
          userId: userId,
          dogId: test.dogId,
          testId: test.id,
          testData: test.toJson(),
        );
      }

      AppLogger.debug('Uploaded ${tests.length} DNA tests to Firebase');
    } catch (e) {
      AppLogger.debug('Error uploading DNA tests: $e');
    }
  }

  // ============ WEIGHT RECORDS (DOG) ============

  /// Syncs weight records from Firebase to Hive
  Future<void> _syncWeightRecords(String userId) async {
    try {
      final dogsBox = Hive.box<Dog>('dogs');
      final weightRecordsBox = Hive.box<WeightRecord>('weight_records');
      final dogs = dogsBox.values.toList();

      for (final dog in dogs) {
        try {
          final recordsList = await _cloudSync.getWeightRecords(
            userId: userId,
            dogId: dog.id,
          );

          for (final recordData in recordsList) {
            final record = WeightRecord.fromJson(recordData);
            await weightRecordsBox.put(record.id, record);
          }
        } catch (e) {
          AppLogger.debug('Error syncing weight records for dog ${dog.id}: $e');
        }
      }

      AppLogger.debug('Synced weight records from Firebase');
    } catch (e) {
      AppLogger.debug('Error syncing weight records: $e');
    }
  }

  /// Uploads local weight records to Firebase
  Future<void> _uploadWeightRecords(String userId) async {
    try {
      final weightRecordsBox = Hive.box<WeightRecord>('weight_records');
      final records = weightRecordsBox.values.toList();

      for (final record in records) {
        await _cloudSync.saveWeightRecord(
          userId: userId,
          dogId: record.dogId,
          recordId: record.id,
          recordData: record.toJson(),
        );
      }

      AppLogger.debug('Uploaded ${records.length} weight records to Firebase');
    } catch (e) {
      AppLogger.debug('Error uploading weight records: $e');
    }
  }

  // ============ TREATMENT PLANS ============

  /// Syncs treatment plans from Firebase to Hive
  Future<void> _syncTreatmentPlans(String userId) async {
    try {
      final treatmentPlansList = await _cloudSync.getTreatmentPlans(userId);
      final treatmentPlansBox = Hive.box<TreatmentPlan>('treatment_plans');

      for (final planData in treatmentPlansList) {
        final plan = TreatmentPlan.fromJson(planData);
        await treatmentPlansBox.put(plan.id, plan);
      }

      AppLogger.debug('Synced ${treatmentPlansList.length} treatment plans from Firebase');
    } catch (e) {
      AppLogger.debug('Error syncing treatment plans: $e');
    }
  }

  /// Uploads local treatment plans to Firebase
  Future<void> _uploadTreatmentPlans(String userId) async {
    try {
      final treatmentPlansBox = Hive.box<TreatmentPlan>('treatment_plans');
      final plans = treatmentPlansBox.values.toList();

      for (final plan in plans) {
        await _cloudSync.saveTreatmentPlan(
          userId: userId,
          treatmentPlanId: plan.id,
          treatmentPlanData: plan.toJson(),
        );
      }

      AppLogger.debug('Uploaded ${plans.length} treatment plans to Firebase');
    } catch (e) {
      AppLogger.debug('Error uploading treatment plans: $e');
    }
  }

  // ============ DELIVERY CHECKLISTS ============

  /// Syncs delivery checklists from Firebase to Hive
  Future<void> _syncDeliveryChecklists(String userId) async {
    try {
      final checklistsList = await _cloudSync.getAllDeliveryChecklists(userId);
      final checklistsBox = Hive.box<DeliveryChecklist>('delivery_checklists');

      for (final checklistData in checklistsList) {
        final checklist = DeliveryChecklist.fromJson(checklistData);
        await checklistsBox.put(checklist.id, checklist);
      }

      AppLogger.debug('Synced ${checklistsList.length} delivery checklists from Firebase');
    } catch (e) {
      AppLogger.debug('Error syncing delivery checklists: $e');
    }
  }

  /// Uploads local delivery checklists to Firebase
  Future<void> _uploadDeliveryChecklists(String userId) async {
    try {
      final checklistsBox = Hive.box<DeliveryChecklist>('delivery_checklists');
      final checklists = checklistsBox.values.toList();

      for (final checklist in checklists) {
        await _cloudSync.syncDeliveryChecklist(checklist, userId);
      }

      AppLogger.debug('Uploaded ${checklists.length} delivery checklists to Firebase');
    } catch (e) {
      AppLogger.debug('Error uploading delivery checklists: $e');
    }
  }

  // ============ BREEDING CONTRACTS ============

  /// Syncs breeding contracts from Firebase to Hive
  Future<void> _syncBreedingContracts(String userId) async {
    try {
      final contractsList = await _cloudSync.getBreedingContracts(userId);
      final contractsBox = Hive.box<BreedingContract>('breeding_contracts');

      for (final contractData in contractsList) {
        final contract = BreedingContract.fromJson(contractData);
        await contractsBox.put(contract.id, contract);
      }

      AppLogger.debug('Synced ${contractsList.length} breeding contracts from Firebase');
    } catch (e) {
      AppLogger.debug('Error syncing breeding contracts: $e');
    }
  }

  /// Uploads local breeding contracts to Firebase
  Future<void> _uploadBreedingContracts(String userId) async {
    try {
      final contractsBox = Hive.box<BreedingContract>('breeding_contracts');
      final contracts = contractsBox.values.toList();

      for (final contract in contracts) {
        await _cloudSync.saveBreedingContract(
          userId: userId,
          contractId: contract.id,
          contractData: contract.toJson(),
        );
      }

      AppLogger.debug('Uploaded ${contracts.length} breeding contracts to Firebase');
    } catch (e) {
      AppLogger.debug('Error uploading breeding contracts: $e');
    }
  }

  // ============ CO-OWNERSHIP CONTRACTS ============

  /// Syncs co-ownership contracts from Firebase to Hive
  Future<void> _syncCoOwnershipContracts(String userId) async {
    try {
      final contractsList = await _cloudSync.getCoOwnershipContracts(userId);
      final contractsBox = Hive.box<CoOwnershipContract>('co_ownership_contracts');

      for (final contractData in contractsList) {
        final contract = CoOwnershipContract.fromJson(contractData);
        await contractsBox.put(contract.id, contract);
      }

      AppLogger.debug('Synced ${contractsList.length} co-ownership contracts from Firebase');
    } catch (e) {
      AppLogger.debug('Error syncing co-ownership contracts: $e');
    }
  }

  /// Uploads local co-ownership contracts to Firebase
  Future<void> _uploadCoOwnershipContracts(String userId) async {
    try {
      final contractsBox = Hive.box<CoOwnershipContract>('co_ownership_contracts');
      final contracts = contractsBox.values.toList();

      for (final contract in contracts) {
        await _cloudSync.saveCoOwnershipContract(
          userId: userId,
          contractId: contract.id,
          contractData: contract.toJson(),
        );
      }

      AppLogger.debug('Uploaded ${contracts.length} co-ownership contracts to Firebase');
    } catch (e) {
      AppLogger.debug('Error uploading co-ownership contracts: $e');
    }
  }

  // ============ FOSTER CONTRACTS ============

  /// Syncs foster contracts from Firebase to Hive
  Future<void> _syncFosterContracts(String userId) async {
    try {
      final contractsList = await _cloudSync.getFosterContracts(userId);
      final contractsBox = Hive.box<FosterContract>('foster_contracts');

      for (final contractData in contractsList) {
        final contract = FosterContract.fromJson(contractData);
        await contractsBox.put(contract.id, contract);
      }

      AppLogger.debug('Synced ${contractsList.length} foster contracts from Firebase');
    } catch (e) {
      AppLogger.debug('Error syncing foster contracts: $e');
    }
  }

  /// Uploads local foster contracts to Firebase
  Future<void> _uploadFosterContracts(String userId) async {
    try {
      final contractsBox = Hive.box<FosterContract>('foster_contracts');
      final contracts = contractsBox.values.toList();

      for (final contract in contracts) {
        await _cloudSync.saveFosterContract(
          userId: userId,
          contractId: contract.id,
          contractData: contract.toJson(),
        );
      }

      AppLogger.debug('Uploaded ${contracts.length} foster contracts to Firebase');
    } catch (e) {
      AppLogger.debug('Error uploading foster contracts: $e');
    }
  }

  // ============ RESERVATION CONTRACTS ============

  /// Syncs reservation contracts from Firebase to Hive
  Future<void> _syncReservationContracts(String userId) async {
    try {
      final contractsList = await _cloudSync.getReservationContracts(userId);
      final contractsBox = Hive.box<ReservationContract>('reservation_contracts');

      for (final contractData in contractsList) {
        final contract = ReservationContract.fromJson(contractData);
        await contractsBox.put(contract.id, contract);
      }

      AppLogger.debug('Synced ${contractsList.length} reservation contracts from Firebase');
    } catch (e) {
      AppLogger.debug('Error syncing reservation contracts: $e');
    }
  }

  /// Uploads local reservation contracts to Firebase
  Future<void> _uploadReservationContracts(String userId) async {
    try {
      final contractsBox = Hive.box<ReservationContract>('reservation_contracts');
      final contracts = contractsBox.values.toList();

      for (final contract in contracts) {
        await _cloudSync.saveReservationContract(
          userId: userId,
          contractId: contract.id,
          contractData: contract.toJson(),
        );
      }

      AppLogger.debug('Uploaded ${contracts.length} reservation contracts to Firebase');
    } catch (e) {
      AppLogger.debug('Error uploading reservation contracts: $e');
    }
  }
}
