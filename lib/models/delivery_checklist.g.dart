// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delivery_checklist.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DeliveryChecklistItemAdapter extends TypeAdapter<DeliveryChecklistItem> {
  @override
  final int typeId = 30;

  @override
  DeliveryChecklistItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DeliveryChecklistItem(
      id: fields[0] as String,
      title: fields[1] as String,
      category: fields[2] as String,
      isCompleted: fields[3] as bool,
      completedDate: fields[4] as DateTime?,
      notes: fields[5] as String?,
      sortOrder: fields[6] as int,
    );
  }

  @override
  void write(BinaryWriter writer, DeliveryChecklistItem obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.category)
      ..writeByte(3)
      ..write(obj.isCompleted)
      ..writeByte(4)
      ..write(obj.completedDate)
      ..writeByte(5)
      ..write(obj.notes)
      ..writeByte(6)
      ..write(obj.sortOrder);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeliveryChecklistItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DeliveryChecklistAdapter extends TypeAdapter<DeliveryChecklist> {
  @override
  final int typeId = 31;

  @override
  DeliveryChecklist read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DeliveryChecklist(
      id: fields[0] as String,
      puppyId: fields[1] as String,
      items: (fields[2] as List).cast<DeliveryChecklistItem>(),
      createdDate: fields[3] as DateTime,
      deliveryDate: fields[4] as DateTime?,
      notes: fields[5] as String?,
      isComplete: fields[6] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, DeliveryChecklist obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.puppyId)
      ..writeByte(2)
      ..write(obj.items)
      ..writeByte(3)
      ..write(obj.createdDate)
      ..writeByte(4)
      ..write(obj.deliveryDate)
      ..writeByte(5)
      ..write(obj.notes)
      ..writeByte(6)
      ..write(obj.isComplete);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeliveryChecklistAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
