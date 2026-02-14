import 'package:hive/hive.dart';

part 'treatment_plan.g.dart';

@HiveType(typeId: 7)
class TreatmentPlan extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String puppyId;

  @HiveField(2)
  late DateTime? wormerDate1; // 1. ormekur

  @HiveField(3)
  late DateTime? wormerDate2; // 2. ormekur

  @HiveField(4)
  late DateTime? wormerDate3; // 3. ormekur

  @HiveField(5)
  late DateTime? vaccineDate1; // 1. vaksinering (8 uker)

  @HiveField(6)
  late DateTime? vaccineDate2; // 2. vaksinering (12 uker)

  @HiveField(7)
  late DateTime? vaccineDate3; // 3. vaksinering (16 uker)

  @HiveField(8)
  late DateTime? microchipDate; // ID-merkingsdato

  @HiveField(9)
  late String? microchipNumber; // ID-merkenummer

  @HiveField(10)
  bool wormerDone1 = false;

  @HiveField(11)
  bool wormerDone2 = false;

  @HiveField(12)
  bool wormerDone3 = false;

  @HiveField(13)
  bool vaccineDone1 = false;

  @HiveField(14)
  bool vaccineDone2 = false;

  @HiveField(15)
  bool vaccineDone3 = false;

  @HiveField(16)
  bool microchipDone = false;

  @HiveField(17)
  String? notes;

  @HiveField(18)
  DateTime dateCreated = DateTime.now();

  TreatmentPlan({
    required this.id,
    required this.puppyId,
    this.wormerDate1,
    this.wormerDate2,
    this.wormerDate3,
    this.vaccineDate1,
    this.vaccineDate2,
    this.vaccineDate3,
    this.microchipDate,
    this.microchipNumber,
    this.notes,
  });

  /// Serialize TreatmentPlan to JSON for Firebase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'puppyId': puppyId,
      'wormerDate1': wormerDate1?.toIso8601String(),
      'wormerDate2': wormerDate2?.toIso8601String(),
      'wormerDate3': wormerDate3?.toIso8601String(),
      'vaccineDate1': vaccineDate1?.toIso8601String(),
      'vaccineDate2': vaccineDate2?.toIso8601String(),
      'vaccineDate3': vaccineDate3?.toIso8601String(),
      'microchipDate': microchipDate?.toIso8601String(),
      'microchipNumber': microchipNumber,
      'wormerDone1': wormerDone1,
      'wormerDone2': wormerDone2,
      'wormerDone3': wormerDone3,
      'vaccineDone1': vaccineDone1,
      'vaccineDone2': vaccineDone2,
      'vaccineDone3': vaccineDone3,
      'microchipDone': microchipDone,
      'notes': notes,
      'dateCreated': dateCreated.toIso8601String(),
    };
  }

  /// Deserialize TreatmentPlan from Firebase JSON
  factory TreatmentPlan.fromJson(Map<String, dynamic> json) {
    final plan = TreatmentPlan(
      id: json['id'] ?? '',
      puppyId: json['puppyId'] ?? '',
      wormerDate1: json['wormerDate1'] != null ? DateTime.parse(json['wormerDate1']) : null,
      wormerDate2: json['wormerDate2'] != null ? DateTime.parse(json['wormerDate2']) : null,
      wormerDate3: json['wormerDate3'] != null ? DateTime.parse(json['wormerDate3']) : null,
      vaccineDate1: json['vaccineDate1'] != null ? DateTime.parse(json['vaccineDate1']) : null,
      vaccineDate2: json['vaccineDate2'] != null ? DateTime.parse(json['vaccineDate2']) : null,
      vaccineDate3: json['vaccineDate3'] != null ? DateTime.parse(json['vaccineDate3']) : null,
      microchipDate: json['microchipDate'] != null ? DateTime.parse(json['microchipDate']) : null,
      microchipNumber: json['microchipNumber'],
      notes: json['notes'],
    );
    plan.wormerDone1 = json['wormerDone1'] ?? false;
    plan.wormerDone2 = json['wormerDone2'] ?? false;
    plan.wormerDone3 = json['wormerDone3'] ?? false;
    plan.vaccineDone1 = json['vaccineDone1'] ?? false;
    plan.vaccineDone2 = json['vaccineDone2'] ?? false;
    plan.vaccineDone3 = json['vaccineDone3'] ?? false;
    plan.microchipDone = json['microchipDone'] ?? false;
    plan.dateCreated = json['dateCreated'] != null 
        ? DateTime.parse(json['dateCreated']) 
        : DateTime.now();
    return plan;
  }
}
