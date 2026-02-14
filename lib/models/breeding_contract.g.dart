// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'breeding_contract.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BreedingContractAdapter extends TypeAdapter<BreedingContract> {
  @override
  final int typeId = 32;

  @override
  BreedingContract read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BreedingContract(
      id: fields[0] as String,
      studId: fields[1] as String,
      damId: fields[2] as String,
      studOwnerName: fields[3] as String,
      studOwnerAddress: fields[4] as String,
      damOwnerName: fields[5] as String,
      damOwnerAddress: fields[6] as String,
      studFee: fields[7] as double,
      paymentTerms: fields[8] as String?,
      additionalTerms: fields[9] as String?,
      contractDate: fields[10] as DateTime,
      status: fields[11] as String?,
      notes: fields[12] as String?,
      dateAdded: fields[13] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, BreedingContract obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.studId)
      ..writeByte(2)
      ..write(obj.damId)
      ..writeByte(3)
      ..write(obj.studOwnerName)
      ..writeByte(4)
      ..write(obj.studOwnerAddress)
      ..writeByte(5)
      ..write(obj.damOwnerName)
      ..writeByte(6)
      ..write(obj.damOwnerAddress)
      ..writeByte(7)
      ..write(obj.studFee)
      ..writeByte(8)
      ..write(obj.paymentTerms)
      ..writeByte(9)
      ..write(obj.additionalTerms)
      ..writeByte(10)
      ..write(obj.contractDate)
      ..writeByte(11)
      ..write(obj.status)
      ..writeByte(12)
      ..write(obj.notes)
      ..writeByte(13)
      ..write(obj.dateAdded);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BreedingContractAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
