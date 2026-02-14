// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'puppy.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PuppyAdapter extends TypeAdapter<Puppy> {
  @override
  final int typeId = 2;

  @override
  Puppy read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Puppy(
      id: fields[0] as String,
      name: fields[1] as String,
      litterId: fields[2] as String,
      dateOfBirth: fields[3] as DateTime,
      gender: fields[4] as String,
      color: fields[5] as String,
      registrationNumber: fields[6] as String?,
      buyerName: fields[7] as String?,
      buyerContact: fields[8] as String?,
      status: fields[9] as String?,
      soldDate: fields[10] as DateTime?,
      deliveredDate: fields[18] as DateTime?,
      notes: fields[11] as String?,
      vaccinated: fields[12] as bool,
      dewormed: fields[13] as bool,
      microchipped: fields[14] as bool,
      birthWeight: fields[15] as double?,
      birthTime: fields[16] as DateTime?,
      birthNotes: fields[17] as String?,
      displayName: fields[19] as String?,
      colorCode: fields[20] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Puppy obj) {
    writer
      ..writeByte(21)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.litterId)
      ..writeByte(3)
      ..write(obj.dateOfBirth)
      ..writeByte(4)
      ..write(obj.gender)
      ..writeByte(5)
      ..write(obj.color)
      ..writeByte(6)
      ..write(obj.registrationNumber)
      ..writeByte(7)
      ..write(obj.buyerName)
      ..writeByte(8)
      ..write(obj.buyerContact)
      ..writeByte(9)
      ..write(obj.status)
      ..writeByte(10)
      ..write(obj.soldDate)
      ..writeByte(18)
      ..write(obj.deliveredDate)
      ..writeByte(11)
      ..write(obj.notes)
      ..writeByte(12)
      ..write(obj.vaccinated)
      ..writeByte(13)
      ..write(obj.dewormed)
      ..writeByte(14)
      ..write(obj.microchipped)
      ..writeByte(15)
      ..write(obj.birthWeight)
      ..writeByte(16)
      ..write(obj.birthTime)
      ..writeByte(17)
      ..write(obj.birthNotes)
      ..writeByte(19)
      ..write(obj.displayName)
      ..writeByte(20)
      ..write(obj.colorCode);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PuppyAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
