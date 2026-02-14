// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'purchase_contract.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PurchaseContractAdapter extends TypeAdapter<PurchaseContract> {
  @override
  final int typeId = 12;

  @override
  PurchaseContract read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PurchaseContract(
      id: fields[0] as String,
      puppyId: fields[1] as String,
      buyerId: fields[2] as String,
      contractDate: fields[3] as DateTime,
      price: fields[4] as double,
      purchaseDate: fields[5] as DateTime?,
      contractNumber: fields[6] as String?,
      status: fields[7] as String?,
      terms: fields[8] as String?,
      spayNeuterRequired: fields[9] as bool,
      returnClauseIncluded: fields[10] as bool,
      paymentTerms: fields[11] as String?,
      notes: fields[12] as String?,
      dateAdded: fields[13] as DateTime?,
      deposit: fields[14] as double?,
      pedigreeDelivered: fields[15] as bool,
      vetCertificateAttached: fields[16] as bool,
      microchipNumber: fields[17] as String?,
      deliveryLocation: fields[18] as String?,
      specialTerms: fields[19] as String?,
      insuranceTransferred: fields[20] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, PurchaseContract obj) {
    writer
      ..writeByte(21)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.puppyId)
      ..writeByte(2)
      ..write(obj.buyerId)
      ..writeByte(3)
      ..write(obj.contractDate)
      ..writeByte(4)
      ..write(obj.price)
      ..writeByte(5)
      ..write(obj.purchaseDate)
      ..writeByte(6)
      ..write(obj.contractNumber)
      ..writeByte(7)
      ..write(obj.status)
      ..writeByte(8)
      ..write(obj.terms)
      ..writeByte(9)
      ..write(obj.spayNeuterRequired)
      ..writeByte(10)
      ..write(obj.returnClauseIncluded)
      ..writeByte(11)
      ..write(obj.paymentTerms)
      ..writeByte(12)
      ..write(obj.notes)
      ..writeByte(13)
      ..write(obj.dateAdded)
      ..writeByte(14)
      ..write(obj.deposit)
      ..writeByte(15)
      ..write(obj.pedigreeDelivered)
      ..writeByte(16)
      ..write(obj.vetCertificateAttached)
      ..writeByte(17)
      ..write(obj.microchipNumber)
      ..writeByte(18)
      ..write(obj.deliveryLocation)
      ..writeByte(19)
      ..write(obj.specialTerms)
      ..writeByte(20)
      ..write(obj.insuranceTransferred);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PurchaseContractAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
