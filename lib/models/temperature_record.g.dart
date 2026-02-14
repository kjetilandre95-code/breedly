// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'temperature_record.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TemperatureRecordAdapter extends TypeAdapter<TemperatureRecord> {
  @override
  final int typeId = 9;

  @override
  TemperatureRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TemperatureRecord(
      id: fields[0] as String,
      litterId: fields[1] as String,
      dateTime: fields[2] as DateTime,
      temperature: fields[3] as double,
      notes: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, TemperatureRecord obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.litterId)
      ..writeByte(2)
      ..write(obj.dateTime)
      ..writeByte(3)
      ..write(obj.temperature)
      ..writeByte(4)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TemperatureRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
