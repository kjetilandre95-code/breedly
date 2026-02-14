// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mating.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MatingAdapter extends TypeAdapter<Mating> {
  @override
  final int typeId = 13;

  @override
  Mating read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Mating(
      id: fields[0] as String,
      sireId: fields[1] as String,
      damId: fields[2] as String,
      damName: fields[3] as String?,
      matingDate: fields[4] as DateTime,
      puppyCount: fields[5] as int?,
      notes: fields[6] as String?,
      litterId: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Mating obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.sireId)
      ..writeByte(2)
      ..write(obj.damId)
      ..writeByte(3)
      ..write(obj.damName)
      ..writeByte(4)
      ..write(obj.matingDate)
      ..writeByte(5)
      ..write(obj.puppyCount)
      ..writeByte(6)
      ..write(obj.notes)
      ..writeByte(7)
      ..write(obj.litterId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MatingAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
