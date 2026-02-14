// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kennel.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class KennelAdapter extends TypeAdapter<Kennel> {
  @override
  final int typeId = 20;

  @override
  Kennel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Kennel(
      id: fields[0] as String,
      name: fields[1] as String,
      ownerId: fields[2] as String,
      ownerEmail: fields[3] as String,
      createdAt: fields[4] as DateTime,
      description: fields[5] as String?,
      breeds: (fields[6] as List).cast<String>(),
      contactEmail: fields[7] as String?,
      contactPhone: fields[8] as String?,
      address: fields[9] as String?,
      website: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Kennel obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.ownerId)
      ..writeByte(3)
      ..write(obj.ownerEmail)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.description)
      ..writeByte(6)
      ..write(obj.breeds)
      ..writeByte(7)
      ..write(obj.contactEmail)
      ..writeByte(8)
      ..write(obj.contactPhone)
      ..writeByte(9)
      ..write(obj.address)
      ..writeByte(10)
      ..write(obj.website);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KennelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
