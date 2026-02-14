// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dna_test.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DnaTestAdapter extends TypeAdapter<DnaTest> {
  @override
  final int typeId = 26;

  @override
  DnaTest read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DnaTest(
      id: fields[0] as String,
      dogId: fields[1] as String,
      testName: fields[2] as String,
      result: fields[3] as String,
      testDate: fields[4] as DateTime?,
      laboratory: fields[5] as String?,
      certificateNumber: fields[6] as String?,
      notes: fields[7] as String?,
      attachmentPath: fields[8] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, DnaTest obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.dogId)
      ..writeByte(2)
      ..write(obj.testName)
      ..writeByte(3)
      ..write(obj.result)
      ..writeByte(4)
      ..write(obj.testDate)
      ..writeByte(5)
      ..write(obj.laboratory)
      ..writeByte(6)
      ..write(obj.certificateNumber)
      ..writeByte(7)
      ..write(obj.notes)
      ..writeByte(8)
      ..write(obj.attachmentPath);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DnaTestAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
