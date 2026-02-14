// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'health.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HealthInfoAdapter extends TypeAdapter<HealthInfo> {
  @override
  final int typeId = 10;

  @override
  HealthInfo read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HealthInfo(
      id: fields[0] as String,
      dogId: fields[1] as String,
      hdStatus: fields[2] as String?,
      hdDate: fields[3] as DateTime?,
      adStatus: fields[4] as int?,
      adDate: fields[5] as DateTime?,
      patellaStatus: fields[6] as String?,
      patellaDate: fields[7] as DateTime?,
      notes: fields[8] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, HealthInfo obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.dogId)
      ..writeByte(2)
      ..write(obj.hdStatus)
      ..writeByte(3)
      ..write(obj.hdDate)
      ..writeByte(4)
      ..write(obj.adStatus)
      ..writeByte(5)
      ..write(obj.adDate)
      ..writeByte(6)
      ..write(obj.patellaStatus)
      ..writeByte(7)
      ..write(obj.patellaDate)
      ..writeByte(8)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HealthInfoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
