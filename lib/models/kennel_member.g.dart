// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kennel_member.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class KennelMemberAdapter extends TypeAdapter<KennelMember> {
  @override
  final int typeId = 21;

  @override
  KennelMember read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return KennelMember(
      userId: fields[0] as String,
      kennelId: fields[1] as String,
      email: fields[2] as String,
      displayName: fields[3] as String?,
      role: fields[4] as String,
      joinedAt: fields[5] as DateTime,
      photoUrl: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, KennelMember obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.userId)
      ..writeByte(1)
      ..write(obj.kennelId)
      ..writeByte(2)
      ..write(obj.email)
      ..writeByte(3)
      ..write(obj.displayName)
      ..writeByte(4)
      ..write(obj.role)
      ..writeByte(5)
      ..write(obj.joinedAt)
      ..writeByte(6)
      ..write(obj.photoUrl);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KennelMemberAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
