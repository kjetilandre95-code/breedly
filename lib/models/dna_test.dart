import 'package:hive/hive.dart';

part 'dna_test.g.dart';

/// Result status for DNA tests
enum DnaTestResult {
  clear,      // Fri/Normal
  carrier,    // Bærer
  affected,   // Affektert
  pending,    // Venter på resultat
  unknown,    // Ukjent
}

@HiveType(typeId: 26)
class DnaTest extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String dogId;

  @HiveField(2)
  late String testName; // Navn på testen (f.eks. 'PRA-prcd', 'DM', 'EIC')

  @HiveField(3)
  late String result; // 'clear', 'carrier', 'affected', 'pending', 'unknown'

  @HiveField(4)
  DateTime? testDate;

  @HiveField(5)
  String? laboratory; // Laboratorium som utførte testen

  @HiveField(6)
  String? certificateNumber; // Sertifikatnummer

  @HiveField(7)
  String? notes;

  @HiveField(8)
  String? attachmentPath; // Sti til sertifikat/vedlegg

  DnaTest({
    required this.id,
    required this.dogId,
    required this.testName,
    required this.result,
    this.testDate,
    this.laboratory,
    this.certificateNumber,
    this.notes,
    this.attachmentPath,
  });

  String get resultDisplay {
    switch (result) {
      case 'clear': return 'Fri (Clear)';
      case 'carrier': return 'Bærer (Carrier)';
      case 'affected': return 'Affektert (Affected)';
      case 'pending': return 'Venter resultat';
      case 'unknown': return 'Ukjent';
      default: return result;
    }
  }

  String get resultShort {
    switch (result) {
      case 'clear': return 'N/N';
      case 'carrier': return 'N/A';
      case 'affected': return 'A/A';
      case 'pending': return '...';
      default: return '?';
    }
  }

  bool get isClear => result == 'clear';
  bool get isCarrier => result == 'carrier';
  bool get isAffected => result == 'affected';
  bool get isPending => result == 'pending';

  /// Serialize DnaTest to JSON for Firebase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dogId': dogId,
      'testName': testName,
      'result': result,
      'testDate': testDate?.toIso8601String(),
      'laboratory': laboratory,
      'certificateNumber': certificateNumber,
      'notes': notes,
      'attachmentPath': attachmentPath,
    };
  }

  /// Deserialize DnaTest from Firebase JSON
  factory DnaTest.fromJson(Map<String, dynamic> json) {
    return DnaTest(
      id: json['id'] ?? '',
      dogId: json['dogId'] ?? '',
      testName: json['testName'] ?? '',
      result: json['result'] ?? 'unknown',
      testDate: json['testDate'] != null 
          ? DateTime.parse(json['testDate']) 
          : null,
      laboratory: json['laboratory'],
      certificateNumber: json['certificateNumber'],
      notes: json['notes'],
      attachmentPath: json['attachmentPath'],
    );
  }
}

/// Common DNA tests for dogs (can be used for suggestions)
class CommonDnaTests {
  static const List<String> tests = [
    'PRA-prcd',
    'PRA-rcd4',
    'PRA-cord1',
    'DM (Degenerative Myelopathy)',
    'EIC (Exercise Induced Collapse)',
    'CNM (Centronuclear Myopathy)',
    'HNPK (Hereditary Nasal Parakeratosis)',
    'SD2 (Skeletal Dysplasia 2)',
    'MCD (Macular Corneal Dystrophy)',
    'OSD (Osteochondrodysplasia)',
    'JHC (Juvenile Hereditary Cataract)',
    'MDR1',
    'vWD (von Willebrand Disease)',
    'HUU (Hyperuricosuria)',
    'DKC (Dilated Cardiomyopathy)',
    'NCL (Neuronal Ceroid Lipofuscinosis)',
    'ICT-A (Ichthyosis Type A)',
    'Long Hair / Furnishings',
    'Dilute (D-locus)',
    'E-locus (Yellow/Red)',
    'B-locus (Brown/Chocolate)',
    'K-locus (Dominant Black)',
    'Annet',
  ];
}
