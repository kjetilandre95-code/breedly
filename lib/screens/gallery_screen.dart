import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:breedly/models/gallery_image.dart';
import 'package:breedly/models/litter.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:breedly/utils/app_bar_builder.dart';

class GalleryScreen extends StatefulWidget {
  final Litter litter;

  const GalleryScreen({super.key, required this.litter});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarBuilder.buildAppBar(
        title: '${widget.litter.damName} - Bildegalleri',
        context: context,
      ),
      body: SafeArea(
        child: ValueListenableBuilder(
          valueListenable: Hive.box<GalleryImage>('gallery_images').listenable(),
          builder: (context, Box<GalleryImage> box, _) {
            final images = box.values
                .where((img) => img.litterId == widget.litter.id)
                .toList()
              ..sort((a, b) => b.dateAdded.compareTo(a.dateAdded));

            if (images.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.image_not_supported,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Ingen bilder ennå',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Trykk på + for å legge til bilder',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              );
            }

            return GridView.builder(
              padding: const EdgeInsets.only(left: 12, right: 12, top: 12, bottom: 88),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: images.length,
              itemBuilder: (context, index) {
              final image = images[index];
              return GestureDetector(
                onTap: () => _showImageDetail(context, image),
                onLongPress: () => _deleteImage(image),
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(
                        File(image.imagePath),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.image_not_supported),
                          );
                        },
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.7),
                              ],
                            ),
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            DateFormat('yyyy-MM-dd').format(image.dateAdded),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
              },
            );
          },
        ),
      ),
    );
  }

  void _showImageDetail(BuildContext context, GalleryImage image) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bildedetaljer'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 300,
                width: 300,
                child: Image.file(
                  File(image.imagePath),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image_not_supported),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Text('Dato: ${DateFormat('yyyy-MM-dd HH:mm').format(image.dateAdded)}'),
              Text('Filstørrelse: ${(image.fileSize / 1024 / 1024).toStringAsFixed(2)} MB'),
              if (image.description != null) ...[
                const SizedBox(height: 8),
                Text('Beskrivelse: ${image.description}'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => _editImageDescription(context, image),
            child: const Text('Rediger'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Lukk'),
          ),
        ],
      ),
    );
  }

  void _editImageDescription(BuildContext context, GalleryImage image) {
    final descriptionController = TextEditingController(text: image.description);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rediger bildenotater'),
        content: TextField(
          controller: descriptionController,
          decoration: const InputDecoration(labelText: 'Beskrivelse'),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Avbryt'),
          ),
          TextButton(
            onPressed: () {
              image.description = descriptionController.text;
              image.save();
              Navigator.pop(context);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Bildenotater oppdatert')),
              );
            },
            child: const Text('Lagre'),
          ),
        ],
      ),
    );
  }

  void _deleteImage(GalleryImage image) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Slett bilde'),
        content: const Text('Er du sikker på at du vil slette dette bildet?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Avbryt'),
          ),
          TextButton(
            onPressed: () async {
              await image.delete();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Bilde slettet')),
                );
              }
            },
            child: const Text('Slett'),
          ),
        ],
      ),
    );
  }
}
