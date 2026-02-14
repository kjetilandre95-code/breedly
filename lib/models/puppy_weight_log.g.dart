// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'puppy_weight_log.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PuppyWeightLogAdapter extends TypeAdapter<PuppyWeightLog> {
  @override
  final int typeId = 3;

  @override
  PuppyWeightLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PuppyWeightLog(
      id: fields[0] as String,
      puppyId: fields[1] as String,
      logDate: fields[2] as DateTime,
      weight: fields[3] as double,
      notes: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, PuppyWeightLog obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.puppyId)
      ..writeByte(2)
      ..write(obj.logDate)
      ..writeByte(3)
      ..write(obj.weight)
      ..writeByte(4)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PuppyWeightLogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
