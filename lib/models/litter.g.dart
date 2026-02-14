// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'litter.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LitterAdapter extends TypeAdapter<Litter> {
  @override
  final int typeId = 0;

  @override
  Litter read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Litter(
      id: fields[0] as String,
      damId: fields[1] as String,
      sireId: fields[2] as String,
      damName: fields[3] as String,
      sireName: fields[4] as String,
      dateOfBirth: fields[5] as DateTime,
      numberOfPuppies: fields[6] as int,
      breed: fields[7] as String,
      expectedNumberOfMales: fields[8] as String?,
      expectedNumberOfFemales: fields[9] as String?,
      actualMalesCount: fields[10] as int,
      actualFemalesCount: fields[11] as int,
      notes: fields[12] as String?,
      isWeaned: fields[13] as bool,
      weanedDate: fields[14] as DateTime?,
      isReadyForSale: fields[15] as bool,
      readyForSaleDate: fields[16] as DateTime?,
      registrationNumber: fields[17] as String?,
      damMatingDate: fields[18] as DateTime?,
      estimatedDueDate: fields[19] as DateTime?,
      damHealthTests: fields[20] as String?,
      sireHealthTests: fields[21] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Litter obj) {
    writer
      ..writeByte(22)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.damId)
      ..writeByte(2)
      ..write(obj.sireId)
      ..writeByte(3)
      ..write(obj.damName)
      ..writeByte(4)
      ..write(obj.sireName)
      ..writeByte(5)
      ..write(obj.dateOfBirth)
      ..writeByte(6)
      ..write(obj.numberOfPuppies)
      ..writeByte(7)
      ..write(obj.breed)
      ..writeByte(8)
      ..write(obj.expectedNumberOfMales)
      ..writeByte(9)
      ..write(obj.expectedNumberOfFemales)
      ..writeByte(10)
      ..write(obj.actualMalesCount)
      ..writeByte(11)
      ..write(obj.actualFemalesCount)
      ..writeByte(12)
      ..write(obj.notes)
      ..writeByte(13)
      ..write(obj.isWeaned)
      ..writeByte(14)
      ..write(obj.weanedDate)
      ..writeByte(15)
      ..write(obj.isReadyForSale)
      ..writeByte(16)
      ..write(obj.readyForSaleDate)
      ..writeByte(17)
      ..write(obj.registrationNumber)
      ..writeByte(18)
      ..write(obj.damMatingDate)
      ..writeByte(19)
      ..write(obj.estimatedDueDate)
      ..writeByte(20)
      ..write(obj.damHealthTests)
      ..writeByte(21)
      ..write(obj.sireHealthTests);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LitterAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
