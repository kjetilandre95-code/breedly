import 'package:hive/hive.dart';

part 'vet_visit.g.dart';

/// Type of veterinary visit
enum VisitType {
  checkup,      // Vanlig helsesjekk
  vaccination,  // Vaksinering
  illness,      // Sykdom
  injury,       // Skade
  surgery,      // Operasjon
  dental,       // Tannbehandling
  emergency,    // Akutt
  other,        // Annet
}

@HiveType(typeId: 24)
class VetVisit extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String dogId;

  @HiveField(2)
  late DateTime visitDate;

  @HiveField(3)
  late String visitType; // 'checkup', 'vaccination', 'illness', 'injury', 'surgery', 'dental', 'emergency', 'other'

  @HiveField(4)
  String? reason; // Grunn for besøket

  @HiveField(5)
  String? diagnosis; // Diagnose

  @HiveField(6)
  String? treatment; // Behandling gitt

  @HiveField(7)
  String? prescription; // Foreskrevne medisiner

  @HiveField(8)
  String? veterinarian; // Veterinærnavn

  @HiveField(9)
  String? clinic; // Klinikknavn

  @HiveField(10)
  double? cost; // Kostnad for besøket

  @HiveField(11)
  DateTime? followUpDate; // Oppfølgingsdato

  @HiveField(12)
  String? notes;

  @HiveField(13)
  List<String>? attachmentPaths; // Stier til vedlagte filer/bilder

  VetVisit({
    required this.id,
    required this.dogId,
    required this.visitDate,
    required this.visitType,
    this.reason,
    this.diagnosis,
    this.treatment,
    this.prescription,
    this.veterinarian,
    this.clinic,
    this.cost,
    this.followUpDate,
    this.notes,
    this.attachmentPaths,
  });

  bool hasFollowUp() => followUpDate != null && followUpDate!.isAfter(DateTime.now());

  bool isFollowUpDue() {
    if (followUpDate == null) return false;
    final now = DateTime.now();
    return followUpDate!.isBefore(now.add(const Duration(days: 7))) && 
           followUpDate!.isAfter(now.subtract(const Duration(days: 1)));
  }

  String get visitTypeDisplay {
    switch (visitType) {
      case 'checkup': return 'Helsesjekk';
      case 'vaccination': return 'Vaksinering';
      case 'illness': return 'Sykdom';
      case 'injury': return 'Skade';
      case 'surgery': return 'Operasjon';
      case 'dental': return 'Tannbehandling';
      case 'emergency': return 'Akutt';
      case 'other': return 'Annet';
      default: return visitType;
    }
  }

  /// Serialize VetVisit to JSON for Firebase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dogId': dogId,
      'visitDate': visitDate.toIso8601String(),
      'visitType': visitType,
      'reason': reason,
      'diagnosis': diagnosis,
      'treatment': treatment,
      'prescription': prescription,
      'veterinarian': veterinarian,
      'clinic': clinic,
      'cost': cost,
      'followUpDate': followUpDate?.toIso8601String(),
      'notes': notes,
      'attachmentPaths': attachmentPaths,
    };
  }

  /// Deserialize VetVisit from Firebase JSON
  factory VetVisit.fromJson(Map<String, dynamic> json) {
    return VetVisit(
      id: json['id'] ?? '',
      dogId: json['dogId'] ?? '',
      visitDate: json['visitDate'] != null 
          ? DateTime.parse(json['visitDate']) 
          : DateTime.now(),
      visitType: json['visitType'] ?? 'other',
      reason: json['reason'],
      diagnosis: json['diagnosis'],
      treatment: json['treatment'],
      prescription: json['prescription'],
      veterinarian: json['veterinarian'],
      clinic: json['clinic'],
      cost: json['cost']?.toDouble(),
      followUpDate: json['followUpDate'] != null 
          ? DateTime.parse(json['followUpDate']) 
          : null,
      notes: json['notes'],
      attachmentPaths: (json['attachmentPaths'] as List<dynamic>?)?.cast<String>(),
    );
  }
}
