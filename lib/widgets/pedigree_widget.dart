import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:breedly/models/dog.dart';
import 'package:breedly/screens/add_dog_screen.dart';
import 'package:breedly/services/auth_service.dart';
import 'package:breedly/services/cloud_sync_service.dart';
import 'package:breedly/services/offline_mode_manager.dart';
import 'package:breedly/utils/pdf_generator.dart';
import 'package:breedly/generated_l10n/app_localizations.dart';
import 'package:breedly/utils/app_theme.dart';
import 'package:breedly/utils/theme_colors.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';

/// Widget for displaying a visual pedigree (up to 5 generations)
class PedigreeWidget extends StatefulWidget {
  final String? dogId;
  final Dog? dog;
  final int generations;

  const PedigreeWidget({
    super.key,
    this.dogId,
    this.dog,
    this.generations = 4,
  });

  @override
  State<PedigreeWidget> createState() => _PedigreeWidgetState();
}

class _PedigreeWidgetState extends State<PedigreeWidget> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentDog = widget.dog ?? _getDogById(widget.dogId);
    
    if (currentDog == null) {
      return Center(
        child: Text(l10n.dogNotFound),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: _buildPedigreeTree(context, currentDog),
        ),
      ),
    );
  }

  Dog? _getDogById(String? id) {
    if (id == null) return null;
    try {
      final box = Hive.box<Dog>('dogs');
      return box.values.where((d) => d.id == id).firstOrNull;
    } catch (e) {
      return null;
    }
  }

  Widget _buildPedigreeTree(BuildContext context, Dog dog) {
    final l10n = AppLocalizations.of(context)!;
    final mother = _getDogById(dog.damId);
    final father = _getDogById(dog.sireId);
    
    // Grandparents
    final maternalGrandmother = _getDogById(mother?.damId);
    final maternalGrandfather = _getDogById(mother?.sireId);
    final paternalGrandmother = _getDogById(father?.damId);
    final paternalGrandfather = _getDogById(father?.sireId);

    // Great-grandparents (generation 3)
    final mmGrandmother = _getDogById(maternalGrandmother?.damId);
    final mmGrandfather = _getDogById(maternalGrandmother?.sireId);
    final mfGrandmother = _getDogById(maternalGrandfather?.damId);
    final mfGrandfather = _getDogById(maternalGrandfather?.sireId);
    final pmGrandmother = _getDogById(paternalGrandmother?.damId);
    final pmGrandfather = _getDogById(paternalGrandmother?.sireId);
    final pfGrandmother = _getDogById(paternalGrandfather?.damId);
    final pfGrandfather = _getDogById(paternalGrandfather?.sireId);

    // Great-great-grandparents (generation 4) — 16 dogs
    // Paternal side
    final pfFather = _getDogById(pfGrandfather?.sireId);
    final pfMother = _getDogById(pfGrandfather?.damId);
    final pfmFather = _getDogById(pfGrandmother?.sireId);
    final pfmMother = _getDogById(pfGrandmother?.damId);
    final pmfFather = _getDogById(pmGrandfather?.sireId);
    final pmfMother = _getDogById(pmGrandfather?.damId);
    final pmmFather = _getDogById(pmGrandmother?.sireId);
    final pmmMother = _getDogById(pmGrandmother?.damId);
    // Maternal side
    final mfFather = _getDogById(mfGrandfather?.sireId);
    final mfMother = _getDogById(mfGrandfather?.damId);
    final mfmFather = _getDogById(mfGrandmother?.sireId);
    final mfmMother = _getDogById(mfGrandmother?.damId);
    final mmfFather = _getDogById(mmGrandfather?.sireId);
    final mmfMother = _getDogById(mmGrandfather?.damId);
    final mmmFather = _getDogById(mmGrandmother?.sireId);
    final mmmMother = _getDogById(mmGrandmother?.damId);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Column 1: The dog itself
        _buildDogCard(context, dog, isMain: true),
        const SizedBox(width: 20),
        _buildConnector(),
        const SizedBox(width: 20),
        
        // Column 2: Parents
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDogCard(context, father, label: l10n.father),
            const SizedBox(height: 20),
            _buildDogCard(context, mother, label: l10n.mother),
          ],
        ),
        const SizedBox(width: 20),
        _buildConnector(),
        const SizedBox(width: 20),
        
        // Column 3: Grandparents
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDogCard(context, paternalGrandfather, label: l10n.paternalGrandfather, small: true),
            const SizedBox(height: 10),
            _buildDogCard(context, paternalGrandmother, label: l10n.paternalGrandmother, small: true),
            const SizedBox(height: 20),
            _buildDogCard(context, maternalGrandfather, label: l10n.maternalGrandfather, small: true),
            const SizedBox(height: 10),
            _buildDogCard(context, maternalGrandmother, label: l10n.maternalGrandmother, small: true),
          ],
        ),
        
        if (widget.generations >= 3) ...[
          const SizedBox(width: 20),
          _buildConnector(),
          const SizedBox(width: 20),
          
          // Column 4: Great-grandparents
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDogCard(context, pfGrandfather, small: true, mini: true),
              const SizedBox(height: 5),
              _buildDogCard(context, pfGrandmother, small: true, mini: true),
              const SizedBox(height: 10),
              _buildDogCard(context, pmGrandfather, small: true, mini: true),
              const SizedBox(height: 5),
              _buildDogCard(context, pmGrandmother, small: true, mini: true),
              const SizedBox(height: 15),
              _buildDogCard(context, mfGrandfather, small: true, mini: true),
              const SizedBox(height: 5),
              _buildDogCard(context, mfGrandmother, small: true, mini: true),
              const SizedBox(height: 10),
              _buildDogCard(context, mmGrandfather, small: true, mini: true),
              const SizedBox(height: 5),
              _buildDogCard(context, mmGrandmother, small: true, mini: true),
            ],
          ),
        ],

        if (widget.generations >= 4) ...[
          const SizedBox(width: 14),
          _buildConnector(),
          const SizedBox(width: 14),
          
          // Column 5: Great-great-grandparents (gen 4)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDogCard(context, pfFather, small: true, mini: true),
              const SizedBox(height: 2),
              _buildDogCard(context, pfMother, small: true, mini: true),
              const SizedBox(height: 6),
              _buildDogCard(context, pfmFather, small: true, mini: true),
              const SizedBox(height: 2),
              _buildDogCard(context, pfmMother, small: true, mini: true),
              const SizedBox(height: 8),
              _buildDogCard(context, pmfFather, small: true, mini: true),
              const SizedBox(height: 2),
              _buildDogCard(context, pmfMother, small: true, mini: true),
              const SizedBox(height: 6),
              _buildDogCard(context, pmmFather, small: true, mini: true),
              const SizedBox(height: 2),
              _buildDogCard(context, pmmMother, small: true, mini: true),
              const SizedBox(height: 12),
              _buildDogCard(context, mfFather, small: true, mini: true),
              const SizedBox(height: 2),
              _buildDogCard(context, mfMother, small: true, mini: true),
              const SizedBox(height: 6),
              _buildDogCard(context, mfmFather, small: true, mini: true),
              const SizedBox(height: 2),
              _buildDogCard(context, mfmMother, small: true, mini: true),
              const SizedBox(height: 8),
              _buildDogCard(context, mmfFather, small: true, mini: true),
              const SizedBox(height: 2),
              _buildDogCard(context, mmfMother, small: true, mini: true),
              const SizedBox(height: 6),
              _buildDogCard(context, mmmFather, small: true, mini: true),
              const SizedBox(height: 2),
              _buildDogCard(context, mmmMother, small: true, mini: true),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildDogCard(
    BuildContext context,
    Dog? dog, {
    String? label,
    bool isMain = false,
    bool small = false,
    bool mini = false,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final width = mini ? 100.0 : (small ? 130.0 : (isMain ? 180.0 : 150.0));
    final height = mini ? 50.0 : (small ? 70.0 : (isMain ? 100.0 : 80.0));
    final fontSize = mini ? 10.0 : (small ? 11.0 : (isMain ? 14.0 : 12.0));

    if (dog == null) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: context.colors.neutral100,
          borderRadius: AppRadius.smAll,
          border: Border.all(color: context.colors.divider),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (label != null && !mini)
                Text(
                  label,
                  style: TextStyle(
                    fontSize: fontSize - 2,
                    color: context.colors.textCaption,
                  ),
                ),
              Text(
                l10n.unknown,
                style: TextStyle(
                  fontSize: fontSize,
                  color: context.colors.textDisabled,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final isFemale = dog.gender == 'Female';
    final color = isFemale ? AppColors.female.withValues(alpha: 0.15) : AppColors.male.withValues(alpha: 0.15);
    final borderColor = isFemale ? AppColors.female : AppColors.male;
    final iconColor = isFemale ? AppColors.female : AppColors.male;

    return GestureDetector(
      onTap: () {
        // Show dog details
        _showDogDetails(context, dog);
      },
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: AppRadius.smAll,
          border: Border.all(color: borderColor, width: isMain ? 2 : 1),
          boxShadow: isMain
              ? [
                  BoxShadow(
                    color: borderColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        padding: EdgeInsets.all(mini ? 4 : 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (label != null && !mini)
              Text(
                label,
                style: TextStyle(
                  fontSize: fontSize - 3,
                  color: iconColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            Row(
              children: [
                Icon(
                  isFemale ? Icons.female : Icons.male,
                  size: mini ? 12 : (small ? 14 : 18),
                  color: iconColor,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    dog.name,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: isMain ? FontWeight.bold : FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (!mini && dog.registrationNumber != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  dog.registrationNumber!,
                  style: TextStyle(
                    fontSize: fontSize - 3,
                    color: context.colors.textMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnector() {
    return Container(
      width: 2,
      height: 200,
      color: context.colors.divider,
    );
  }

  void _showDogDetails(BuildContext context, Dog dog) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(
                dog.gender == 'Female' ? Icons.female : Icons.male,
                color: dog.gender == 'Female' ? AppColors.female : AppColors.male,
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(dog.name, overflow: TextOverflow.ellipsis)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow(l10n.breed, dog.breed),
              _buildDetailRow(l10n.color, dog.color),
              if (dog.registrationNumber != null)
                _buildDetailRow(l10n.registrationNumber, dog.registrationNumber!),
              _buildDetailRow(l10n.gender, dog.gender == 'Female' ? l10n.female : l10n.male),
              _buildDetailRow(
                l10n.born,
                '${dog.dateOfBirth.day}.${dog.dateOfBirth.month}.${dog.dateOfBirth.year}',
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dog.isPedigreeOnly ? l10n.pedigreeOnly : l10n.visibleInDogList,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          dog.isPedigreeOnly
                              ? l10n.pedigreeOnlyDescription
                              : l10n.visibleInDogListDescription,
                          style: TextStyle(fontSize: 12, color: context.colors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: !dog.isPedigreeOnly,
                    onChanged: (visible) async {
                      dog.isPedigreeOnly = !visible;
                      await dog.save();
                      // Sync to Firebase
                      final auth = AuthService();
                      if (auth.isAuthenticated && OfflineModeManager().isOnline) {
                        try {
                          await CloudSyncService().saveDog(
                            userId: auth.currentUserId!,
                            dogId: dog.id,
                            dogData: dog.toJson(),
                          );
                        } catch (_) {}
                      }
                      setDialogState(() {});
                      // Rebuild pedigree tree
                      if (mounted) setState(() {});
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.close),
            ),
            FilledButton.icon(
              onPressed: () async {
                Navigator.pop(dialogContext);
                final result = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddDogScreen(dogToEdit: dog),
                  ),
                );
                if (result == true && mounted) {
                  setState(() {});
                }
              },
              icon: const Icon(Icons.edit_rounded, size: 18),
              label: Text(l10n.edit),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: context.colors.textCaption,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}

/// Full-screen pedigree view
class PedigreeScreen extends StatelessWidget {
  final Dog dog;

  const PedigreeScreen({
    super.key,
    required this.dog,
  });

  Future<void> _exportPDF(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final pdf = await PDFGenerator.generatePedigreePDF(dog);
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: l10n.pedigreeFilename(dog.name.replaceAll(' ', '_')),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.couldNotGeneratePdf(e.toString())),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.pedigreeTitle(dog.name)),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded),
            tooltip: l10n.exportPdf,
            onPressed: () => _exportPDF(context),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: Text(l10n.aboutPedigree),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('• ${l10n.pedigreeTipTapDetails}'),
                      const SizedBox(height: 8),
                      Text('• ${l10n.pedigreeTipPinkFemales}'),
                      const SizedBox(height: 4),
                      Text('• ${l10n.pedigreeTipBlueMales}'),
                      const SizedBox(height: 8),
                      Text('• ${l10n.pedigreeTipScroll}'),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: Text(l10n.ok),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: PedigreeWidget(
        dog: dog,

        generations: 4,
      ),
    );
  }
}

