import 'package:hive/hive.dart';

part 'gallery_image.g.dart';

@HiveType(typeId: 8)
class GalleryImage extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String litterId; // Hvilket kull bildet tilhører

  @HiveField(2)
  String? puppyId; // Hvilken valp (valgfritt)

  @HiveField(3)
  late String imagePath; // Lokal filbane

  @HiveField(4)
  late DateTime dateAdded;

  @HiveField(5)
  String? description; // Bildenotater

  @HiveField(6)
  late int fileSize; // Filstørrelse i bytes

  GalleryImage({
    required this.id,
    required this.litterId,
    this.puppyId,
    required this.imagePath,
    required this.dateAdded,
    this.description,
    required this.fileSize,
  });
}
