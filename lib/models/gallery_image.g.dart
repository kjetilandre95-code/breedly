// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gallery_image.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GalleryImageAdapter extends TypeAdapter<GalleryImage> {
  @override
  final int typeId = 8;

  @override
  GalleryImage read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GalleryImage(
      id: fields[0] as String,
      litterId: fields[1] as String,
      puppyId: fields[2] as String?,
      imagePath: fields[3] as String,
      dateAdded: fields[4] as DateTime,
      description: fields[5] as String?,
      fileSize: fields[6] as int,
    );
  }

  @override
  void write(BinaryWriter writer, GalleryImage obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.litterId)
      ..writeByte(2)
      ..write(obj.puppyId)
      ..writeByte(3)
      ..write(obj.imagePath)
      ..writeByte(4)
      ..write(obj.dateAdded)
      ..writeByte(5)
      ..write(obj.description)
      ..writeByte(6)
      ..write(obj.fileSize);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GalleryImageAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
