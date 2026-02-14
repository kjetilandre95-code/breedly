// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'treatment_plan.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TreatmentPlanAdapter extends TypeAdapter<TreatmentPlan> {
  @override
  final int typeId = 7;

  @override
  TreatmentPlan read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TreatmentPlan(
      id: fields[0] as String,
      puppyId: fields[1] as String,
      wormerDate1: fields[2] as DateTime?,
      wormerDate2: fields[3] as DateTime?,
      wormerDate3: fields[4] as DateTime?,
      vaccineDate1: fields[5] as DateTime?,
      vaccineDate2: fields[6] as DateTime?,
      vaccineDate3: fields[7] as DateTime?,
      microchipDate: fields[8] as DateTime?,
      microchipNumber: fields[9] as String?,
      notes: fields[17] as String?,
    )
      ..wormerDone1 = fields[10] as bool
      ..wormerDone2 = fields[11] as bool
      ..wormerDone3 = fields[12] as bool
      ..vaccineDone1 = fields[13] as bool
      ..vaccineDone2 = fields[14] as bool
      ..vaccineDone3 = fields[15] as bool
      ..microchipDone = fields[16] as bool
      ..dateCreated = fields[18] as DateTime;
  }

  @override
  void write(BinaryWriter writer, TreatmentPlan obj) {
    writer
      ..writeByte(19)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.puppyId)
      ..writeByte(2)
      ..write(obj.wormerDate1)
      ..writeByte(3)
      ..write(obj.wormerDate2)
      ..writeByte(4)
      ..write(obj.wormerDate3)
      ..writeByte(5)
      ..write(obj.vaccineDate1)
      ..writeByte(6)
      ..write(obj.vaccineDate2)
      ..writeByte(7)
      ..write(obj.vaccineDate3)
      ..writeByte(8)
      ..write(obj.microchipDate)
      ..writeByte(9)
      ..write(obj.microchipNumber)
      ..writeByte(10)
      ..write(obj.wormerDone1)
      ..writeByte(11)
      ..write(obj.wormerDone2)
      ..writeByte(12)
      ..write(obj.wormerDone3)
      ..writeByte(13)
      ..write(obj.vaccineDone1)
      ..writeByte(14)
      ..write(obj.vaccineDone2)
      ..writeByte(15)
      ..write(obj.vaccineDone3)
      ..writeByte(16)
      ..write(obj.microchipDone)
      ..writeByte(17)
      ..write(obj.notes)
      ..writeByte(18)
      ..write(obj.dateCreated);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TreatmentPlanAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
