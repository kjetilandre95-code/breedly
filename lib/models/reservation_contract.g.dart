// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reservation_contract.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ReservationContractAdapter extends TypeAdapter<ReservationContract> {
  @override
  final int typeId = 35;

  @override
  ReservationContract read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ReservationContract(
      id: fields[0] as String,
      puppyId: fields[1] as String,
      buyerId: fields[2] as String,
      reservationFee: fields[3] as double,
      totalPrice: fields[4] as double,
      notes: fields[5] as String?,
      contractDate: fields[6] as DateTime,
      status: fields[7] as String?,
      dateAdded: fields[8] as DateTime?,
      convertedToPurchaseContractId: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ReservationContract obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.puppyId)
      ..writeByte(2)
      ..write(obj.buyerId)
      ..writeByte(3)
      ..write(obj.reservationFee)
      ..writeByte(4)
      ..write(obj.totalPrice)
      ..writeByte(5)
      ..write(obj.notes)
      ..writeByte(6)
      ..write(obj.contractDate)
      ..writeByte(7)
      ..write(obj.status)
      ..writeByte(8)
      ..write(obj.dateAdded)
      ..writeByte(9)
      ..write(obj.convertedToPurchaseContractId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReservationContractAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
