// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'foster_contract.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FosterContractAdapter extends TypeAdapter<FosterContract> {
  @override
  final int typeId = 34;

  @override
  FosterContract read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FosterContract(
      id: fields[0] as String,
      dogId: fields[1] as String,
      ownerName: fields[2] as String,
      ownerAddress: fields[3] as String,
      fosterName: fields[4] as String,
      fosterAddress: fields[5] as String,
      startDate: fields[6] as DateTime,
      endDate: fields[7] as DateTime?,
      breedingTerms: fields[8] as String,
      expenseTerms: fields[9] as String,
      returnConditions: fields[10] as String,
      additionalTerms: fields[11] as String?,
      contractDate: fields[12] as DateTime,
      status: fields[13] as String?,
      notes: fields[14] as String?,
      dateAdded: fields[15] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, FosterContract obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.dogId)
      ..writeByte(2)
      ..write(obj.ownerName)
      ..writeByte(3)
      ..write(obj.ownerAddress)
      ..writeByte(4)
      ..write(obj.fosterName)
      ..writeByte(5)
      ..write(obj.fosterAddress)
      ..writeByte(6)
      ..write(obj.startDate)
      ..writeByte(7)
      ..write(obj.endDate)
      ..writeByte(8)
      ..write(obj.breedingTerms)
      ..writeByte(9)
      ..write(obj.expenseTerms)
      ..writeByte(10)
      ..write(obj.returnConditions)
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
      other is FosterContractAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
