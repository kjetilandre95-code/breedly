// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kennel_invitation.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class KennelInvitationAdapter extends TypeAdapter<KennelInvitation> {
  @override
  final int typeId = 22;

  @override
  KennelInvitation read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return KennelInvitation(
      id: fields[0] as String,
      code: fields[1] as String,
      kennelId: fields[2] as String,
      kennelName: fields[3] as String,
      invitedByUserId: fields[4] as String,
      invitedByEmail: fields[5] as String,
      invitedEmail: fields[6] as String?,
      role: fields[7] as String,
      createdAt: fields[8] as DateTime,
      expiresAt: fields[9] as DateTime,
      isUsed: fields[10] as bool,
      usedByUserId: fields[11] as String?,
      usedAt: fields[12] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, KennelInvitation obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.code)
      ..writeByte(2)
      ..write(obj.kennelId)
      ..writeByte(3)
      ..write(obj.kennelName)
      ..writeByte(4)
      ..write(obj.invitedByUserId)
      ..writeByte(5)
      ..write(obj.invitedByEmail)
      ..writeByte(6)
      ..write(obj.invitedEmail)
      ..writeByte(7)
      ..write(obj.role)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.expiresAt)
      ..writeByte(10)
      ..write(obj.isUsed)
      ..writeByte(11)
      ..write(obj.usedByUserId)
      ..writeByte(12)
      ..write(obj.usedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KennelInvitationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
