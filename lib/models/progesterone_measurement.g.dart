// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'progesterone_measurement.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProgesteroneMeasurementAdapter
    extends TypeAdapter<ProgesteroneMeasurement> {
  @override
  final int typeId = 14;

  @override
  ProgesteroneMeasurement read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProgesteroneMeasurement(
      id: fields[0] as String,
      dogId: fields[1] as String,
      dateMeasured: fields[2] as DateTime,
      value: fields[3] as double,
      notes: fields[4] as String?,
      veterinarian: fields[5] as String?,
      unit: fields[6] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ProgesteroneMeasurement obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.dogId)
      ..writeByte(2)
      ..write(obj.dateMeasured)
      ..writeByte(3)
      ..write(obj.value)
      ..writeByte(4)
      ..write(obj.notes)
      ..writeByte(5)
      ..write(obj.veterinarian)
      ..writeByte(6)
      ..write(obj.unit);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProgesteroneMeasurementAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
