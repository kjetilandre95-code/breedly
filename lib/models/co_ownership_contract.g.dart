// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'co_ownership_contract.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CoOwnershipContractAdapter extends TypeAdapter<CoOwnershipContract> {
  @override
  final int typeId = 33;

  @override
  CoOwnershipContract read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CoOwnershipContract(
      id: fields[0] as String,
      dogId: fields[1] as String,
      owner1Name: fields[2] as String,
      owner1Address: fields[3] as String,
      owner2Name: fields[4] as String,
      owner2Address: fields[5] as String,
      owner1Percentage: fields[6] as int,
      primaryCaretaker: fields[7] as String,
      breedingRights: fields[8] as String,
      showRights: fields[9] as String,
      expenseSharing: fields[10] as String,
      additionalTerms: fields[11] as String?,
      contractDate: fields[12] as DateTime,
      status: fields[13] as String?,
      notes: fields[14] as String?,
      dateAdded: fields[15] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, CoOwnershipContract obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.dogId)
      ..writeByte(2)
      ..write(obj.owner1Name)
      ..writeByte(3)
      ..write(obj.owner1Address)
      ..writeByte(4)
      ..write(obj.owner2Name)
      ..writeByte(5)
      ..write(obj.owner2Address)
      ..writeByte(6)
      ..write(obj.owner1Percentage)
      ..writeByte(7)
      ..write(obj.primaryCaretaker)
      ..writeByte(8)
      ..write(obj.breedingRights)
      ..writeByte(9)
      ..write(obj.showRights)
      ..writeByte(10)
      ..write(obj.expenseSharing)
      ..writeByte(11)
      ..write(obj.additionalTerms)
      ..writeByte(12)
      ..write(obj.contractDate)
      ..writeByte(13)
      ..write(obj.status)
      ..writeByte(14)
      ..write(obj.notes)
      ..writeByte(15)
      ..write(obj.dateAdded);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoOwnershipContractAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
