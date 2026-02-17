import 'package:flutter/material.dart';
import 'package:breedly/widgets/pedigree_scanner_widget.dart';
import 'package:breedly/services/pedigree_scanner_service.dart';
import 'package:breedly/utils/theme_colors.dart';
import 'package:breedly/utils/app_theme.dart';

/// Test screen for pedigree scanner functionality
class PedigreeScannerTestScreen extends StatelessWidget {
  const PedigreeScannerTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Stamtavle-skanner'),
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
                          'Testing av stamtavle-skanner',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.info,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const Text(
                      'Denne funksjonen bruker Google ML Kit for å:',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildBullet('Lese tekst fra bilder (OCR)'),
                    _buildBullet('Finne registreringsnummer'),
                    _buildBullet('Identifisere hundenavn'),
                    _buildBullet('Gjenkjenne foreldre (Far/Mor)'),
                    _buildBullet('Ekstrahere fødselsdatoer'),
                    const SizedBox(height: AppSpacing.md),
                    const Text(
                      '💡 Tips: Bruk et tydelig bilde av en stamtavle for beste resultat.',
                      style: TextStyle(
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
                    const Text(
                      'Testinstruksjoner',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildStep('1', 'Ta et bilde av en stamtavle'),
                    _buildStep('2', 'Vent mens ML Kit prosesserer bildet'),
                    _buildStep('3', 'Se resultatene og nøyaktigheten'),
                    _buildStep('4', 'Rediger data hvis nødvendig'),
                    _buildStep('5', 'Lagre hunden(e) i databasen'),
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
                        const Text(
                          'Eksempel på data som kan gjenkjennes',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const Text('Registreringsnummer:'),
                    const Text(
                      '  • N 12345/18\n  • NO 54321/2020\n  • DK 67890\n  • SE 123456',
                      style: TextStyle(fontFamily: 'monospace'),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const Text('Nøkkelord:'),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Skanneresultat'),
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
                    'Nøyaktighet: ${(result.confidence * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _getConfidenceColor(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${result.totalDogs} hunder funnet',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Main dog
          if (result.dog != null) ...[
            const Text(
              'Hovedhund',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildDogCard(context, result.dog!),
            const SizedBox(height: AppSpacing.lg),
          ],

          // Parents
          if (result.parents.isNotEmpty) ...[
            const Text(
              'Foreldre',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.sm),
            ...result.parents.map((dog) => _buildDogCard(context, dog)),
            const SizedBox(height: AppSpacing.lg),
          ],

          // Grandparents
          if (result.grandparents.isNotEmpty) ...[
            const Text(
              'Besteforeldre',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                  const Text(
                    'Debug-informasjon',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text('Totalt funnet: ${result.totalDogs} hunder'),
                  Text('Confidence: ${result.confidence.toStringAsFixed(3)}'),
                  Text('Vellykket: ${result.isSuccessful}'),
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
              _buildInfoRow(context, 'Reg.nr:', dog.registrationNumber!),
            if (dog.breed != null) _buildInfoRow(context, 'Rase:', dog.breed!),
            if (dog.birthDate != null) _buildInfoRow(context, 'Født:', dog.birthDate!),
            if (dog.color != null) _buildInfoRow(context, 'Farge:', dog.color!),
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
