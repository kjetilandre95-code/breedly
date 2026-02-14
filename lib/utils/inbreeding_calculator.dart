import 'package:hive_flutter/hive_flutter.dart';
import 'package:breedly/models/dog.dart';

/// Calculator for inbreeding coefficient (COI)
/// Uses Wright's coefficient of inbreeding formula
class InbreedingCalculator {
  static final InbreedingCalculator _instance = InbreedingCalculator._internal();
  factory InbreedingCalculator() => _instance;
  InbreedingCalculator._internal();

  /// Calculate Coefficient of Inbreeding (COI) for a potential mating
  /// Returns a value between 0 and 1 (0% to 100%)
  /// 
  /// Recommended COI levels:
  /// - < 5%: Excellent
  /// - 5-10%: Acceptable
  /// - 10-15%: High (use with caution)
  /// - > 15%: Very high (not recommended)
  double calculateCOI({
    required String motherId,
    required String fatherId,
    int generations = 5,
  }) {
    final mother = _getDogById(motherId);
    final father = _getDogById(fatherId);

    if (mother == null || father == null) {
      return 0.0;
    }

    // Build lookup for matching dogs by registration number
    final regNumberToIds = _buildRegistrationMap();

    // Get ancestors for both parents, including themselves at generation 0
    final motherAncestors = _getAncestorsWithSelf(motherId, generations, regNumberToIds);
    final fatherAncestors = _getAncestorsWithSelf(fatherId, generations, regNumberToIds);

    // Find common ancestors (using normalized IDs to handle duplicates)
    final commonAncestors = <String>{};
    for (final ancestor in motherAncestors.keys) {
      if (fatherAncestors.containsKey(ancestor)) {
        commonAncestors.add(ancestor);
      }
    }

    if (commonAncestors.isEmpty) {
      return 0.0;
    }

    // Calculate COI using Wright's formula
    // COI = Σ (0.5)^(n1+n2+1) × (1 + FA)
    // Where n1 = generations from sire to common ancestor
    //       n2 = generations from dam to common ancestor
    //       FA = inbreeding coefficient of common ancestor

    double coi = 0.0;

    for (final ancestorId in commonAncestors) {
      final pathsFromMother = motherAncestors[ancestorId]!;
      final pathsFromFather = fatherAncestors[ancestorId]!;

      for (final n1 in pathsFromMother) {
        for (final n2 in pathsFromFather) {
          // Skip if both are at generation 0 (same dog on both sides, not inbreeding)
          if (n1 == 0 && n2 == 0) continue;
          
          // Simplified: assuming FA = 0 for common ancestors
          // A more complete implementation would recursively calculate FA
          final contribution = 0.5 * (1 / (1 << (n1 + n2 + 1)));
          coi += contribution;
        }
      }
    }

    return coi.clamp(0.0, 1.0);
  }

  /// Build a map of registration numbers to dog IDs for duplicate detection
  Map<String, String> _buildRegistrationMap() {
    final map = <String, String>{};
    try {
      final box = Hive.box<Dog>('dogs');
      for (final dog in box.values) {
        if (dog.registrationNumber != null && dog.registrationNumber!.isNotEmpty) {
          // Use the first dog found with this registration number as the canonical ID
          map.putIfAbsent(dog.registrationNumber!.toUpperCase(), () => dog.id);
        }
      }
    } catch (e) {
      // Ignore errors
    }
    return map;
  }

  /// Normalize a dog ID to handle duplicates by registration number
  String _normalizeId(String dogId, Map<String, String> regNumberToIds) {
    final dog = _getDogById(dogId);
    if (dog != null && dog.registrationNumber != null && dog.registrationNumber!.isNotEmpty) {
      final normalizedId = regNumberToIds[dog.registrationNumber!.toUpperCase()];
      if (normalizedId != null) {
        return normalizedId;
      }
    }
    return dogId;
  }

  /// Get all ancestors and their generation distances, including self at generation 0
  /// Returns `Map<ancestorId, List<generationDistance>>`
  Map<String, List<int>> _getAncestorsWithSelf(String dogId, int maxGenerations, Map<String, String> regNumberToIds) {
    final ancestors = <String, List<int>>{};
    
    // Include the dog itself at generation 0
    final normalizedId = _normalizeId(dogId, regNumberToIds);
    ancestors[normalizedId] = [0];
    
    _collectAncestorsNormalized(dogId, 0, maxGenerations, ancestors, regNumberToIds);
    return ancestors;
  }

  void _collectAncestorsNormalized(
    String dogId,
    int generation,
    int maxGenerations,
    Map<String, List<int>> ancestors,
    Map<String, String> regNumberToIds,
  ) {
    if (generation >= maxGenerations) return;

    final dog = _getDogById(dogId);
    if (dog == null) return;

    // Add mother
    if (dog.damId != null) {
      final normalizedDamId = _normalizeId(dog.damId!, regNumberToIds);
      ancestors.putIfAbsent(normalizedDamId, () => []).add(generation + 1);
      _collectAncestorsNormalized(dog.damId!, generation + 1, maxGenerations, ancestors, regNumberToIds);
    }

    // Add father
    if (dog.sireId != null) {
      final normalizedSireId = _normalizeId(dog.sireId!, regNumberToIds);
      ancestors.putIfAbsent(normalizedSireId, () => []).add(generation + 1);
      _collectAncestorsNormalized(dog.sireId!, generation + 1, maxGenerations, ancestors, regNumberToIds);
    }
  }

  Dog? _getDogById(String id) {
    try {
      final box = Hive.box<Dog>('dogs');
      return box.values.where((d) => d.id == id).firstOrNull;
    } catch (e) {
      return null;
    }
  }

  /// Get risk assessment based on COI value
  InbreedingRisk assessRisk(double coi) {
    final percentage = coi * 100;
    
    if (percentage < 3) {
      return InbreedingRisk.veryLow;
    } else if (percentage < 6.25) {
      return InbreedingRisk.low;
    } else if (percentage < 12.5) {
      return InbreedingRisk.moderate;
    } else if (percentage < 25) {
      return InbreedingRisk.high;
    } else {
      return InbreedingRisk.veryHigh;
    }
  }

  /// Get common ancestors between two dogs
  List<CommonAncestor> findCommonAncestors({
    required String motherId,
    required String fatherId,
    int generations = 5,
  }) {
    final regNumberToIds = _buildRegistrationMap();
    final motherAncestors = _getAncestorsWithSelf(motherId, generations, regNumberToIds);
    final fatherAncestors = _getAncestorsWithSelf(fatherId, generations, regNumberToIds);

    final commonAncestors = <CommonAncestor>[];

    for (final ancestorId in motherAncestors.keys) {
      if (fatherAncestors.containsKey(ancestorId)) {
        final dog = _getDogById(ancestorId);
        if (dog != null) {
          final minDistanceMother = motherAncestors[ancestorId]!.reduce((a, b) => a < b ? a : b);
          final minDistanceFather = fatherAncestors[ancestorId]!.reduce((a, b) => a < b ? a : b);
          
          // Skip if both are at generation 0 (the dogs themselves)
          if (minDistanceMother == 0 && minDistanceFather == 0) continue;

          commonAncestors.add(CommonAncestor(
            dog: dog,
            generationsFromMother: minDistanceMother,
            generationsFromFather: minDistanceFather,
            occurrencesInMother: motherAncestors[ancestorId]!.length,
            occurrencesInFather: fatherAncestors[ancestorId]!.length,
          ));
        }
      }
    }

    // Sort by closest relationship
    commonAncestors.sort((a, b) {
      final totalA = a.generationsFromMother + a.generationsFromFather;
      final totalB = b.generationsFromMother + b.generationsFromFather;
      return totalA.compareTo(totalB);
    });

    return commonAncestors;
  }
}

enum InbreedingRisk {
  veryLow,
  low,
  moderate,
  high,
  veryHigh,
}

extension InbreedingRiskExtension on InbreedingRisk {
  String get label {
    switch (this) {
      case InbreedingRisk.veryLow:
        return 'Svært lav';
      case InbreedingRisk.low:
        return 'Lav';
      case InbreedingRisk.moderate:
        return 'Moderat';
      case InbreedingRisk.high:
        return 'Høy';
      case InbreedingRisk.veryHigh:
        return 'Svært høy';
    }
  }

  String get description {
    switch (this) {
      case InbreedingRisk.veryLow:
        return 'Utmerket genetisk variasjon';
      case InbreedingRisk.low:
        return 'God genetisk variasjon';
      case InbreedingRisk.moderate:
        return 'Akseptabel, men vær oppmerksom';
      case InbreedingRisk.high:
        return 'Anbefales ikke, økt risiko for helseproblemer';
      case InbreedingRisk.veryHigh:
        return 'Frarådes sterkt, betydelig risiko';
    }
  }

  String get color {
    switch (this) {
      case InbreedingRisk.veryLow:
        return '#4CAF50'; // Green
      case InbreedingRisk.low:
        return '#8BC34A'; // Light green
      case InbreedingRisk.moderate:
        return '#FFC107'; // Amber
      case InbreedingRisk.high:
        return '#FF9800'; // Orange
      case InbreedingRisk.veryHigh:
        return '#F44336'; // Red
    }
  }
}

class CommonAncestor {
  final Dog dog;
  final int generationsFromMother;
  final int generationsFromFather;
  final int occurrencesInMother;
  final int occurrencesInFather;

  CommonAncestor({
    required this.dog,
    required this.generationsFromMother,
    required this.generationsFromFather,
    required this.occurrencesInMother,
    required this.occurrencesInFather,
  });

  String get relationship {
    final total = generationsFromMother + generationsFromFather;
    if (total == 2) {
      return 'Søsken (samme forelder)';
    } else if (total == 3) {
      return 'Halvsøsken eller onkel/tante-nevø/niese';
    } else if (total == 4) {
      return 'Søskenbarn';
    } else if (total == 5) {
      return 'Halvt søskenbarn';
    } else {
      return '$total generasjoner';
    }
  }
}
