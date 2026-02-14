// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'medical_treatment.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MedicalTreatmentAdapter extends TypeAdapter<MedicalTreatment> {
  @override
  final int typeId = 25;

  @override
  MedicalTreatment read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MedicalTreatment(
      id: fields[0] as String,
      dogId: fields[1] as String,
      name: fields[2] as String,
      treatmentType: fields[3] as String,
      dateGiven: fields[4] as DateTime,
      nextDueDate: fields[5] as DateTime?,
      intervalDays: fields[6] as int?,
      dosage: fields[7] as String?,
      manufacturer: fields[8] as String?,
      batchNumber: fields[9] as String?,
      reminderEnabled: fields[10] as bool,
      reminderDaysBefore: fields[11] as int?,
      notes: fields[12] as String?,
      veterinarian: fields[13] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, MedicalTreatment obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.dogId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.treatmentType)
      ..writeByte(4)
      ..write(obj.dateGiven)
      ..writeByte(5)
      ..write(obj.nextDueDate)
      ..writeByte(6)
      ..write(obj.intervalDays)
      ..writeByte(7)
      ..write(obj.dosage)
      ..writeByte(8)
      ..write(obj.manufacturer)
      ..writeByte(9)
      ..write(obj.batchNumber)
      ..writeByte(10)
      ..write(obj.reminderEnabled)
      ..writeByte(11)
      ..write(obj.reminderDaysBefore)
      ..writeByte(12)
      ..write(obj.notes)
      ..writeByte(13)
      ..write(obj.veterinarian);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MedicalTreatmentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
