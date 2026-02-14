// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vet_visit.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class VetVisitAdapter extends TypeAdapter<VetVisit> {
  @override
  final int typeId = 24;

  @override
  VetVisit read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VetVisit(
      id: fields[0] as String,
      dogId: fields[1] as String,
      visitDate: fields[2] as DateTime,
      visitType: fields[3] as String,
      reason: fields[4] as String?,
      diagnosis: fields[5] as String?,
      treatment: fields[6] as String?,
      prescription: fields[7] as String?,
      veterinarian: fields[8] as String?,
      clinic: fields[9] as String?,
      cost: fields[10] as double?,
      followUpDate: fields[11] as DateTime?,
      notes: fields[12] as String?,
      attachmentPaths: (fields[13] as List?)?.cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, VetVisit obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.dogId)
      ..writeByte(2)
      ..write(obj.visitDate)
      ..writeByte(3)
      ..write(obj.visitType)
      ..writeByte(4)
      ..write(obj.reason)
      ..writeByte(5)
      ..write(obj.diagnosis)
      ..writeByte(6)
      ..write(obj.treatment)
      ..writeByte(7)
      ..write(obj.prescription)
      ..writeByte(8)
      ..write(obj.veterinarian)
      ..writeByte(9)
      ..write(obj.clinic)
      ..writeByte(10)
      ..write(obj.cost)
      ..writeByte(11)
      ..write(obj.followUpDate)
      ..writeByte(12)
      ..write(obj.notes)
      ..writeByte(13)
      ..write(obj.attachmentPaths);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VetVisitAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
