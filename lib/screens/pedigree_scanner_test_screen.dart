import 'package:flutter/material.dart';
import 'package:breedly/generated_l10n/app_localizations.dart';
import 'package:breedly/widgets/pedigree_scanner_widget.dart';
import 'package:breedly/services/pedigree_scanner_service.dart';
import 'package:breedly/utils/theme_colors.dart';
import 'package:breedly/utils/app_theme.dart';

/// Test screen for pedigree scanner functionality
class PedigreeScannerTestScreen extends StatelessWidget {
  const PedigreeScannerTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.testPedigreeScanner),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Information card
            Card(
              color: AppColors.info.withValues(alpha: 0.1),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: AppColors.info),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          l10n.testingScannerInfo,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.info,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      l10n.scannerUsesInfo,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildBullet(l10n.readTextFromImages),
                    _buildBullet(l10n.findRegistrationNumbers),
                    _buildBullet(l10n.identifyDogNames),
                    _buildBullet(l10n.recognizeParents),
                    _buildBullet(l10n.extractBirthDates),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      '💡 ${l10n.tipClearImage}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            // Scanner widget
            PedigreeScannerWidget(
              onScanComplete: (result) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PedigreeScanResultScreen(
                      result: result,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: AppSpacing.xxl),

            // Test instructions
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.testInstructions,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildStep('1', l10n.step1TakePhoto),
                    _buildStep('2', l10n.step2WaitProcessing),
                    _buildStep('3', l10n.step3SeeResults),
                    _buildStep('4', l10n.step4EditData),
                    _buildStep('5', l10n.step5SaveDogs),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Example data
            Card(
              color: AppColors.success.withValues(alpha: 0.1),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb_outline, color: AppColors.success),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          l10n.exampleDataRecognized,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(l10n.registrationNumberColon),
                    const Text(
                      '  • N 12345/18\n  • NO 54321/2020\n  • DK 67890\n  • SE 123456',
                      style: TextStyle(fontFamily: 'monospace'),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(l10n.keywords),
                    const Text(
                      '  • Far: / Sire: / Father:\n  • Mor: / Dam: / Mother:\n  • Rase: / Breed:',
                      style: TextStyle(fontFamily: 'monospace'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBullet(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 16, color: AppColors.success),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _buildStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.primary,
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

/// Screen to display scan results for testing
class PedigreeScanResultScreen extends StatelessWidget {
  final PedigreeScanResult result;

  const PedigreeScanResultScreen({
    super.key,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.scanResult),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // Overall confidence
          Card(
            color: _getConfidenceColor().withValues(alpha: 0.1),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  Icon(
                    _getConfidenceIcon(),
                    size: 48,
                    color: _getConfidenceColor(),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.accuracyPercent('${(result.confidence * 100).toStringAsFixed(0)}%'),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _getConfidenceColor(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.dogsFound(result.totalDogs),
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Main dog
          if (result.dog != null) ...[
            Text(
              l10n.mainDog,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildDogCard(context, result.dog!),
            const SizedBox(height: AppSpacing.lg),
          ],

          // Parents
          if (result.parents.isNotEmpty) ...[
            Text(
              l10n.parents,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.sm),
            ...result.parents.map((dog) => _buildDogCard(context, dog)),
            const SizedBox(height: AppSpacing.lg),
          ],

          // Grandparents
          if (result.grandparents.isNotEmpty) ...[
            Text(
              l10n.grandparents,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.sm),
            ...result.grandparents.map((dog) => _buildDogCard(context, dog)),
          ],

          // Debug info
          const SizedBox(height: AppSpacing.xxl),
          Card(
            color: context.colors.neutral100,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.debugInfo,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(l10n.totalDogsFound(result.totalDogs)),
                  Text('${l10n.scanConfidence}: ${result.confidence.toStringAsFixed(3)}'),
                  Text(l10n.scanSuccessful('${result.isSuccessful}')),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDogCard(BuildContext context, ScannedDog dog) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: dog.confidence > 0.7
                      ? AppColors.success.withValues(alpha: 0.2)
                      : AppColors.warning.withValues(alpha: 0.2),
                  child: Icon(
                    dog.gender == 'Male' ? Icons.male : Icons.female,
                    color: dog.confidence > 0.7
                        ? AppColors.success
                        : AppColors.warning,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dog.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (dog.position != null)
                        Text(
                          dog.position!,
                          style: TextStyle(
                            fontSize: 12,
                            color: context.colors.textMuted,
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  '${(dog.confidence * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: dog.confidence > 0.7 ? AppColors.success : AppColors.warning,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (dog.registrationNumber != null ||
                dog.breed != null ||
                dog.birthDate != null) ...[
              const SizedBox(height: AppSpacing.sm),
              const Divider(height: 1),
              const SizedBox(height: AppSpacing.sm),
            ],
            if (dog.registrationNumber != null)
              _buildInfoRow(context, '${AppLocalizations.of(context)!.registrationNumber}:', dog.registrationNumber!),
            if (dog.breed != null) _buildInfoRow(context, '${AppLocalizations.of(context)!.breed}:', dog.breed!),
            if (dog.birthDate != null) _buildInfoRow(context, '${AppLocalizations.of(context)!.birthDate}:', dog.birthDate!),
            if (dog.color != null) _buildInfoRow(context, '${AppLocalizations.of(context)!.color}:', dog.color!),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: context.colors.textDisabled,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Color _getConfidenceColor() {
    if (result.confidence > 0.8) return AppColors.success;
    if (result.confidence > 0.6) return AppColors.warning;
    return AppColors.error;
  }

  IconData _getConfidenceIcon() {
    if (result.confidence > 0.8) return Icons.check_circle;
    if (result.confidence > 0.6) return Icons.warning;
    return Icons.error;
  }
}
