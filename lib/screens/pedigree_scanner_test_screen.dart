import 'package:flutter/material.dart';
import 'package:breedly/widgets/pedigree_scanner_widget.dart';
import 'package:breedly/services/pedigree_scanner_service.dart';

/// Test screen for pedigree scanner functionality
class PedigreeScannerTestScreen extends StatelessWidget {
  const PedigreeScannerTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Stamtavle-skanner'),
        backgroundColor: Colors.indigo,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Information card
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Testing av stamtavle-skanner',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[900],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Denne funksjonen bruker Google ML Kit for å:',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    _buildBullet('Lese tekst fra bilder (OCR)'),
                    _buildBullet('Finne registreringsnummer'),
                    _buildBullet('Identifisere hundenavn'),
                    _buildBullet('Gjenkjenne foreldre (Far/Mor)'),
                    _buildBullet('Ekstrahere fødselsdatoer'),
                    const SizedBox(height: 12),
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
            const SizedBox(height: 24),

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

            const SizedBox(height: 24),

            // Test instructions
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
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
                    const SizedBox(height: 12),
                    _buildStep('1', 'Ta et bilde av en stamtavle'),
                    _buildStep('2', 'Vent mens ML Kit prosesserer bildet'),
                    _buildStep('3', 'Se resultatene og nøyaktigheten'),
                    _buildStep('4', 'Rediger data hvis nødvendig'),
                    _buildStep('5', 'Lagre hunden(e) i databasen'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Example data
            Card(
              color: Colors.green[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb_outline, color: Colors.green[700]),
                        const SizedBox(width: 8),
                        const Text(
                          'Eksempel på data som kan gjenkjennes',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text('Registreringsnummer:'),
                    const Text(
                      '  • N 12345/18\n  • NO 54321/2020\n  • DK 67890\n  • SE 123456',
                      style: TextStyle(fontFamily: 'monospace'),
                    ),
                    const SizedBox(height: 8),
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
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 16, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _buildStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: Colors.indigo,
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
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
        backgroundColor: Colors.indigo,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Overall confidence
          Card(
            color: _getConfidenceColor().withValues(alpha: 0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(
                    _getConfidenceIcon(),
                    size: 48,
                    color: _getConfidenceColor(),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Nøyaktighet: ${(result.confidence * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _getConfidenceColor(),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${result.totalDogs} hunder funnet',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Main dog
          if (result.dog != null) ...[
            const Text(
              'Hovedhund',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildDogCard(result.dog!),
            const SizedBox(height: 16),
          ],

          // Parents
          if (result.parents.isNotEmpty) ...[
            const Text(
              'Foreldre',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...result.parents.map((dog) => _buildDogCard(dog)),
            const SizedBox(height: 16),
          ],

          // Grandparents
          if (result.grandparents.isNotEmpty) ...[
            const Text(
              'Besteforeldre',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...result.grandparents.map((dog) => _buildDogCard(dog)),
          ],

          // Debug info
          const SizedBox(height: 24),
          Card(
            color: Colors.grey[100],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Debug-informasjon',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
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

  Widget _buildDogCard(ScannedDog dog) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: dog.confidence > 0.7
                      ? Colors.green[100]
                      : Colors.orange[100],
                  child: Icon(
                    dog.gender == 'Male' ? Icons.male : Icons.female,
                    color: dog.confidence > 0.7
                        ? Colors.green[700]
                        : Colors.orange[700],
                  ),
                ),
                const SizedBox(width: 12),
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
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  '${(dog.confidence * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: dog.confidence > 0.7 ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (dog.registrationNumber != null ||
                dog.breed != null ||
                dog.birthDate != null) ...[
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 8),
            ],
            if (dog.registrationNumber != null)
              _buildInfoRow('Reg.nr:', dog.registrationNumber!),
            if (dog.breed != null) _buildInfoRow('Rase:', dog.breed!),
            if (dog.birthDate != null) _buildInfoRow('Født:', dog.birthDate!),
            if (dog.color != null) _buildInfoRow('Farge:', dog.color!),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.grey,
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
    if (result.confidence > 0.8) return Colors.green;
    if (result.confidence > 0.6) return Colors.orange;
    return Colors.red;
  }

  IconData _getConfidenceIcon() {
    if (result.confidence > 0.8) return Icons.check_circle;
    if (result.confidence > 0.6) return Icons.warning;
    return Icons.error;
  }
}
