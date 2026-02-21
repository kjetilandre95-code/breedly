// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dog.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DogAdapter extends TypeAdapter<Dog> {
  @override
  final int typeId = 1;

  @override
  Dog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Dog(
      id: fields[0] as String,
      name: fields[1] as String,
      breed: fields[2] as String,
      color: fields[3] as String,
      dateOfBirth: fields[4] as DateTime,
      gender: fields[5] as String,
      registrationNumber: fields[6] as String?,
      notes: fields[7] as String?,
      damId: fields[8] as String?,
      sireId: fields[9] as String?,
      heatCycles: (fields[10] as List).cast<DateTime>(),
      healthInfoId: fields[11] as String?,
      vaccineIds: (fields[12] as List?)?.cast<String>(),
      championships: (fields[13] as List).cast<String>(),
      deathDate: fields[14] as DateTime?,
      isPedigreeOnly: fields[15] as bool,
      tilleggskravCompleted: fields[16] == null ? false : fields[16] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Dog obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.breed)
      ..writeByte(3)
      ..write(obj.color)
      ..writeByte(4)
      ..write(obj.dateOfBirth)
      ..writeByte(5)
      ..write(obj.gender)
      ..writeByte(6)
      ..write(obj.registrationNumber)
      ..writeByte(7)
      ..write(obj.notes)
      ..writeByte(8)
      ..write(obj.damId)
      ..writeByte(9)
      ..write(obj.sireId)
      ..writeByte(10)
      ..write(obj.heatCycles)
      ..writeByte(11)
      ..write(obj.healthInfoId)
      ..writeByte(12)
      ..write(obj.vaccineIds)
      ..writeByte(13)
      ..write(obj.championships)
      ..writeByte(14)
      ..write(obj.deathDate)
      ..writeByte(15)
      ..write(obj.isPedigreeOnly)
      ..writeByte(16)
      ..write(obj.tilleggskravCompleted);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
