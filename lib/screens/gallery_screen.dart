import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:breedly/models/gallery_image.dart';
import 'package:breedly/models/litter.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:breedly/utils/app_bar_builder.dart';
import 'package:breedly/utils/theme_colors.dart';
import 'package:breedly/utils/app_theme.dart';
import 'package:breedly/generated_l10n/app_localizations.dart';

class GalleryScreen extends StatefulWidget {
  final Litter litter;

  const GalleryScreen({super.key, required this.litter});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBarBuilder.buildAppBar(
        title: l10n.photoGalleryTitle(widget.litter.damName),
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
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withValues(alpha: 0.15),
                        borderRadius: AppRadius.lgAll,
                      ),
                      child: Icon(
                        Icons.image_not_supported,
                        size: 64,
                        color: context.colors.textDisabled,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    Text(
                      l10n.noImagesYet,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      l10n.tapToAddPhotos,
                      style: TextStyle(
                        color: context.colors.textMuted,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              );
            }

            return GridView.builder(
              padding: const EdgeInsets.only(left: AppSpacing.md, right: AppSpacing.md, top: AppSpacing.md, bottom: 88),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
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
                    borderRadius: AppRadius.mdAll,
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(
                        File(image.imagePath),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: context.colors.borderSubtle,
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
                          padding: const EdgeInsets.all(AppSpacing.md),
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
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.imageDetails),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300, maxWidth: 300),
                child: Image.file(
                  File(image.imagePath),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: context.colors.borderSubtle,
                      child: const Icon(Icons.image_not_supported),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(l10n.dateWithValue(DateFormat('yyyy-MM-dd HH:mm').format(image.dateAdded))),
              Text(l10n.fileSizeLabel((image.fileSize / 1024 / 1024).toStringAsFixed(2))),
              if (image.description != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(l10n.descriptionWithValue(image.description!)),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => _editImageDescription(context, image),
            child: Text(l10n.edit),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  void _editImageDescription(BuildContext context, GalleryImage image) {
    final l10n = AppLocalizations.of(context)!;
    final descriptionController = TextEditingController(text: image.description);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.editImageNotes),
        content: TextField(
          controller: descriptionController,
          decoration: InputDecoration(labelText: l10n.descriptionLabel),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              image.description = descriptionController.text;
              image.save();
              Navigator.pop(context);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.imageNotesUpdated)),
              );
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  void _deleteImage(GalleryImage image) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteImage),
        content: Text(l10n.confirmDeleteImage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              await image.delete();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.imageDeleted)),
                );
              }
            },
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }
}
