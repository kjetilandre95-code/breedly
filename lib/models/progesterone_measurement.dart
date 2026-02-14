import 'package:hive/hive.dart';

part 'progesterone_measurement.g.dart';

/// Enum for progesterone measurement units
enum ProgesteroneUnit { ngMl, nmolL }

@HiveType(typeId: 14)
class ProgesteroneMeasurement extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String dogId;

  @HiveField(2)
  late DateTime dateMeasured;

  @HiveField(3)
  late double value; // Progesteron value (unit determined by 'unit' field)

  @HiveField(4)
  String? notes;

  @HiveField(5)
  String? veterinarian;

  @HiveField(6)
  String unit; // 'ng/mL' or 'nmol/L' - defaults to ng/mL for backwards compatibility

  ProgesteroneMeasurement({
    required this.id,
    required this.dogId,
    required this.dateMeasured,
    required this.value,
    this.notes,
    this.veterinarian,
    this.unit = 'ng/mL',
  });

  /// Get the value converted to ng/mL (for consistent calculations)
  double get valueInNgMl {
    if (unit == 'nmol/L') {
      // Conversion: 1 ng/mL ≈ 3.18 nmol/L
      return value / 3.18;
    }
    return value;
  }

  /// Get the value converted to nmol/L
  double get valueInNmolL {
    if (unit == 'ng/mL') {
      // Conversion: 1 ng/mL ≈ 3.18 nmol/L
      return value * 3.18;
    }
    return value;
  }

  /// Get display string with unit
  String get displayValue {
    return '${value.toStringAsFixed(1)} $unit';
  }

  /// Serialize to JSON for Firebase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dogId': dogId,
      'dateMeasured': dateMeasured.toIso8601String(),
      'value': value,
      'notes': notes,
      'veterinarian': veterinarian,
      'unit': unit,
    };
  }

  /// Deserialize from Firebase JSON
  factory ProgesteroneMeasurement.fromJson(Map<String, dynamic> json) {
    return ProgesteroneMeasurement(
      id: json['id'] ?? '',
      dogId: json['dogId'] ?? '',
      dateMeasured: json['dateMeasured'] != null
          ? DateTime.parse(json['dateMeasured'])
          : DateTime.now(),
      value: (json['value'] ?? 0.0).toDouble(),
      notes: json['notes'],
      veterinarian: json['veterinarian'],
      unit: json['unit'] ?? 'ng/mL',
    );
  }

  /// Get cycle status based on progesterone level
  /// Uses ng/mL as reference (converts if needed)
  ProgesteroneStatus getStatus() {
    final ngMl = valueInNgMl;
    
    if (ngMl < 2.0) {
      return ProgesteroneStatus.basal;
    } else if (ngMl >= 2.0 && ngMl < 5.0) {
      return ProgesteroneStatus.lhPeak;
    } else if (ngMl >= 5.0 && ngMl < 10.0) {
      return ProgesteroneStatus.ovulation;
    } else if (ngMl >= 10.0 && ngMl < 20.0) {
      return ProgesteroneStatus.fertileWindow;
    } else if (ngMl >= 20.0 && ngMl < 30.0) {
      return ProgesteroneStatus.lateWindow;
    } else {
      return ProgesteroneStatus.tooLate;
    }
  }

  /// Get interpretation of progesterone level (legacy method)
  String getInterpretation() {
    return getStatus().description;
  }
}

/// Progesterone cycle status with recommendations
enum ProgesteroneStatus {
  basal,
  lhPeak,
  ovulation,
  fertileWindow,
  lateWindow,
  tooLate,
}

extension ProgesteroneStatusExtension on ProgesteroneStatus {
  String get label {
    switch (this) {
      case ProgesteroneStatus.basal:
        return 'Basalnivå';
      case ProgesteroneStatus.lhPeak:
        return 'LH-topp';
      case ProgesteroneStatus.ovulation:
        return 'Eggløsning';
      case ProgesteroneStatus.fertileWindow:
        return 'Fertilt vindu';
      case ProgesteroneStatus.lateWindow:
        return 'Sent i vinduet';
      case ProgesteroneStatus.tooLate:
        return 'For sent';
    }
  }

  String get description {
    switch (this) {
      case ProgesteroneStatus.basal:
        return 'For tidlig - test igjen om 2-3 dager';
      case ProgesteroneStatus.lhPeak:
        return 'LH-topp - eggløsning om ca. 48 timer';
      case ProgesteroneStatus.ovulation:
        return 'Eggløsning - eggene må modnes i 2 dager';
      case ProgesteroneStatus.fertileWindow:
        return 'Fertilt vindu - beste tid for parring!';
      case ProgesteroneStatus.lateWindow:
        return 'Sent i vinduet - parr med én gang!';
      case ProgesteroneStatus.tooLate:
        return 'For sent - vinduet er sannsynligvis passert';
    }
  }

  String get recommendation {
    switch (this) {
      case ProgesteroneStatus.basal:
        return 'Test igjen om 2-3 dager';
      case ProgesteroneStatus.lhPeak:
        return 'Mål daglig! Parring om 3-4 dager';
      case ProgesteroneStatus.ovulation:
        return 'Parr om 2 dager for best resultat';
      case ProgesteroneStatus.fertileWindow:
        return 'PARR NÅ - optimal tid!';
      case ProgesteroneStatus.lateWindow:
        return 'PARR MED ÉN GANG!';
      case ProgesteroneStatus.tooLate:
        return 'Vinduet er sannsynligvis passert';
    }
  }

  String get rangeNgMl {
    switch (this) {
      case ProgesteroneStatus.basal:
        return '< 2 ng/mL';
      case ProgesteroneStatus.lhPeak:
        return '2-3 ng/mL';
      case ProgesteroneStatus.ovulation:
        return '5-8 ng/mL';
      case ProgesteroneStatus.fertileWindow:
        return '10-20 ng/mL';
      case ProgesteroneStatus.lateWindow:
        return '20-30 ng/mL';
      case ProgesteroneStatus.tooLate:
        return '> 30 ng/mL';
    }
  }

  String get rangeNmolL {
    switch (this) {
      case ProgesteroneStatus.basal:
        return '< 6 nmol/L';
      case ProgesteroneStatus.lhPeak:
        return '6-10 nmol/L';
      case ProgesteroneStatus.ovulation:
        return '15-25 nmol/L';
      case ProgesteroneStatus.fertileWindow:
        return '30-60 nmol/L';
      case ProgesteroneStatus.lateWindow:
        return '60-90 nmol/L';
      case ProgesteroneStatus.tooLate:
        return '> 90 nmol/L';
    }
  }

  bool get isUrgent {
    return this == ProgesteroneStatus.fertileWindow || 
           this == ProgesteroneStatus.lateWindow;
  }

  bool get canMate {
    return this == ProgesteroneStatus.ovulation ||
           this == ProgesteroneStatus.fertileWindow || 
           this == ProgesteroneStatus.lateWindow;
  }
}
