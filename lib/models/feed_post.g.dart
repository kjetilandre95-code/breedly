// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feed_post.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FeedPostAdapter extends TypeAdapter<FeedPost> {
  @override
  final int typeId = 36;

  @override
  FeedPost read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      final key = reader.readByte();
      final value = reader.read();
      fields[key] = value;
    }
    return FeedPost(
      id: fields[0] as String,
      authorId: fields[1] as String,
      kennelId: fields[2] as String,
      kennelName: fields[3] as String,
      breed: fields[4] as String,
      type: fields[5] as String,
      visibility: fields[6] as String,
      timestamp: fields[7] as DateTime,
      title: fields[8] as String,
      subtitle: fields[9] as String?,
      dogName: fields[10] as String?,
      likes: fields[11] == null ? 0 : fields[11] as int,
      contentData: fields[12] == null
          ? null
          : (fields[12] as Map?)?.cast<String, dynamic>(),
      isRead: fields[13] == null ? false : fields[13] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, FeedPost obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.authorId)
      ..writeByte(2)
      ..write(obj.kennelId)
      ..writeByte(3)
      ..write(obj.kennelName)
      ..writeByte(4)
      ..write(obj.breed)
      ..writeByte(5)
      ..write(obj.type)
      ..writeByte(6)
      ..write(obj.visibility)
      ..writeByte(7)
      ..write(obj.timestamp)
      ..writeByte(8)
      ..write(obj.title)
      ..writeByte(9)
      ..write(obj.subtitle)
      ..writeByte(10)
      ..write(obj.dogName)
      ..writeByte(11)
      ..write(obj.likes)
      ..writeByte(12)
      ..write(obj.contentData)
      ..writeByte(13)
      ..write(obj.isRead);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FeedPostAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
