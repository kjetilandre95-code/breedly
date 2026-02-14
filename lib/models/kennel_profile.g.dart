// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kennel_profile.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class KennelProfileAdapter extends TypeAdapter<KennelProfile> {
  @override
  final int typeId = 15;

  @override
  KennelProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return KennelProfile(
      id: fields[0] as String,
      kennelName: fields[1] as String?,
      breeds: (fields[2] as List).cast<String>(),
      contactEmail: fields[3] as String?,
      contactPhone: fields[4] as String?,
      address: fields[5] as String?,
      website: fields[6] as String?,
      description: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, KennelProfile obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.kennelName)
      ..writeByte(2)
      ..write(obj.breeds)
      ..writeByte(3)
      ..write(obj.contactEmail)
      ..writeByte(4)
      ..write(obj.contactPhone)
      ..writeByte(5)
      ..write(obj.address)
      ..writeByte(6)
      ..write(obj.website)
      ..writeByte(7)
      ..write(obj.description);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KennelProfileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
