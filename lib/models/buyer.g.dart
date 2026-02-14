// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buyer.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BuyerAdapter extends TypeAdapter<Buyer> {
  @override
  final int typeId = 4;

  @override
  Buyer read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Buyer(
      id: fields[0] as String,
      name: fields[1] as String,
      email: fields[2] as String?,
      phone: fields[3] as String?,
      address: fields[4] as String?,
      preferences: fields[5] as String?,
      notes: fields[6] as String?,
      puppyReserved: fields[7] as String?,
      litterId: fields[8] as String?,
      purchaseDate: fields[9] as DateTime?,
      dateAdded: fields[10] as DateTime?,
      waitlistPosition: fields[11] as int?,
      waitlistDate: fields[12] as DateTime?,
      waitlistStatus: fields[13] as String?,
      preferredGender: fields[14] as String?,
      preferredColor: fields[15] as String?,
      depositPaid: fields[16] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, Buyer obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.email)
      ..writeByte(3)
      ..write(obj.phone)
      ..writeByte(4)
      ..write(obj.address)
      ..writeByte(5)
      ..write(obj.preferences)
      ..writeByte(6)
      ..write(obj.notes)
      ..writeByte(7)
      ..write(obj.puppyReserved)
      ..writeByte(8)
      ..write(obj.litterId)
      ..writeByte(9)
      ..write(obj.purchaseDate)
      ..writeByte(10)
      ..write(obj.dateAdded)
      ..writeByte(11)
      ..write(obj.waitlistPosition)
      ..writeByte(12)
      ..write(obj.waitlistDate)
      ..writeByte(13)
      ..write(obj.waitlistStatus)
      ..writeByte(14)
      ..write(obj.preferredGender)
      ..writeByte(15)
      ..write(obj.preferredColor)
      ..writeByte(16)
      ..write(obj.depositPaid);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BuyerAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
