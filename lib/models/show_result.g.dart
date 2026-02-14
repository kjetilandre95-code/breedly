// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'show_result.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ShowResultAdapter extends TypeAdapter<ShowResult> {
  @override
  final int typeId = 23;

  @override
  ShowResult read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ShowResult(
      id: fields[0] as String,
      dogId: fields[1] as String,
      date: fields[2] as DateTime,
      showName: fields[3] as String,
      judge: fields[4] as String?,
      showClass: fields[5] as String,
      quality: fields[6] as String,
      placement: fields[7] as String?,
      certificates: (fields[8] as List?)?.cast<String>(),
      groupResult: fields[9] as String?,
      bisResult: fields[10] as String?,
      critique: fields[11] as String?,
      notes: fields[12] as String?,
      showType: fields[13] as String?,
      hasCK: fields[14] == null ? false : fields[14] as bool,
      classPlacement: fields[15] as String?,
      bestOfSexPlacement: fields[16] as String?,
      groupJudge: fields[17] as String?,
      bisJudge: fields[18] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ShowResult obj) {
    writer
      ..writeByte(19)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.dogId)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.showName)
      ..writeByte(4)
      ..write(obj.judge)
      ..writeByte(5)
      ..write(obj.showClass)
      ..writeByte(6)
      ..write(obj.quality)
      ..writeByte(7)
      ..write(obj.placement)
      ..writeByte(8)
      ..write(obj.certificates)
      ..writeByte(9)
      ..write(obj.groupResult)
      ..writeByte(10)
      ..write(obj.bisResult)
      ..writeByte(11)
      ..write(obj.critique)
      ..writeByte(12)
      ..write(obj.notes)
      ..writeByte(13)
      ..write(obj.showType)
      ..writeByte(14)
      ..write(obj.hasCK)
      ..writeByte(15)
      ..write(obj.classPlacement)
      ..writeByte(16)
      ..write(obj.bestOfSexPlacement)
      ..writeByte(17)
      ..write(obj.groupJudge)
      ..writeByte(18)
      ..write(obj.bisJudge);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShowResultAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
