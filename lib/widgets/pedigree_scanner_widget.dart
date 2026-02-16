import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:breedly/services/pedigree_scanner_service.dart';
import 'package:breedly/generated_l10n/app_localizations.dart';
import 'package:breedly/utils/app_theme.dart';

/// Widget for scanning pedigree documents
class PedigreeScannerWidget extends StatefulWidget {
  final Function(PedigreeScanResult) onScanComplete;

  const PedigreeScannerWidget({
    super.key,
    required this.onScanComplete,
  });

  @override
  State<PedigreeScannerWidget> createState() => _PedigreeScannerWidgetState();
}

class _PedigreeScannerWidgetState extends State<PedigreeScannerWidget> {
  final PedigreeScannerService _scannerService = PedigreeScannerService();
  bool _isScanning = false;

  Future<void> _scanFromCamera() async {
    setState(() => _isScanning = true);

    try {
      final result = await _scannerService.scanPedigree(
        source: PedigreeScanSource.camera,
      );

      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;

      if (result == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.noImageSelected),
            backgroundColor: Colors.orange,
          ),
        );
      } else if (result.dog == null && result.parents.isEmpty) {
        // Show error from rawText
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.rawText ?? l10n.couldNotReadPedigree),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      } else {
        widget.onScanComplete(result);
      }
    } finally {
      if (mounted) {
        setState(() => _isScanning = false);
      }
    }
  }

  Future<void> _scanFromGallery() async {
    setState(() => _isScanning = true);

    try {
      final result = await _scannerService.scanPedigree(
        source: PedigreeScanSource.gallery,
      );

      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;

      if (result == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.noImageSelected),
            backgroundColor: Colors.orange,
          ),
        );
      } else if (result.dog == null && result.parents.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.rawText ?? l10n.couldNotReadPedigree),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      } else {
        widget.onScanComplete(result);
      }
    } finally {
      if (mounted) {
        setState(() => _isScanning = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.document_scanner, color: Colors.blue[700]),
              const SizedBox(width: 8),
              Text(
                l10n.scanPedigree,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[900],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.scanPedigreeSubtitle,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          if (_isScanning)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 8),
                    Text(l10n.processingImage),
                  ],
                ),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _scanFromCamera,
                    icon: const Icon(Icons.camera_alt),
                    label: Text(l10n.takePhoto),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _scanFromGallery,
                    icon: const Icon(Icons.photo_library),
                    label: Text(l10n.selectImage),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 8),
          _buildHelpText(),
        ],
      ),
    );
  }

  Widget _buildHelpText() {
    final l10n = AppLocalizations.of(context)!;
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: Text(
        l10n.tipsForBestResults,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTip(l10n.tipGoodLighting),
              _buildTip(l10n.tipHoldCameraOver),
              _buildTip(l10n.tipAvoidShadows),
              _buildTip(l10n.tipPedigreeReadable),
              const SizedBox(height: 8),
              Text(
                '💡 ${l10n.tipEditAfterScanning}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue[700],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 14, color: Colors.green[600]),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }
}

/// Screen for reviewing scanned pedigree data before saving
class PedigreeScanReviewScreen extends StatefulWidget {
  final PedigreeScanResult scanResult;

  const PedigreeScanReviewScreen({
    super.key,
    required this.scanResult,
  });

  @override
  State<PedigreeScanReviewScreen> createState() =>
      _PedigreeScanReviewScreenState();
}

class _PedigreeScanReviewScreenState extends State<PedigreeScanReviewScreen> {
  late List<ScannedDog> _editableDogs;
  bool _showRawText = false;
  bool _treeView = true;
  final PedigreeScannerService _scannerService = PedigreeScannerService();

  @override
  void initState() {
    super.initState();
    _editableDogs = [
      if (widget.scanResult.dog != null) widget.scanResult.dog!,
      ...widget.scanResult.parents,
      ...widget.scanResult.grandparents,
      ...widget.scanResult.greatGrandparents,
      ...widget.scanResult.greatGreatGrandparents,
    ];
  }

  ScannedDog? _findByPosition(String position) {
    final matches = _editableDogs.where((d) => d.position == position);
    return matches.isEmpty ? null : matches.first;
  }

  void _editOrAddAtPosition(String position, String defaultGender) {
    final idx = _editableDogs.indexWhere((d) => d.position == position);
    if (idx >= 0) {
      _editDog(_editableDogs[idx], idx);
    } else {
      final newDog = ScannedDog(
        name: 'Ukjent',
        confidence: 1.0,
        position: position,
        gender: defaultGender,
      );
      setState(() => _editableDogs.add(newDog));
      _editDog(newDog, _editableDogs.length - 1, removeOnCancel: true);
    }
  }

  String _genderForPosition(String position) {
    const femalePositions = ['Mor', 'Farmor', 'Mormor', 'Farfars mor', 'Farmors mor', 'Morfars mor', 'Mormors mor'];
    return femalePositions.contains(position) ? 'Female' : 'Male';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.reviewScannedData),
        actions: [
          IconButton(
            icon: Icon(_treeView ? Icons.list : Icons.account_tree),
            onPressed: () => setState(() => _treeView = !_treeView),
            tooltip: _treeView ? l10n.listView : l10n.treeView,
          ),
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: () => _openScannerSettings(context),
            tooltip: l10n.scannerSettings,
          ),
          IconButton(
            icon: const Icon(Icons.text_snippet_outlined),
            onPressed: () => setState(() => _showRawText = !_showRawText),
            tooltip: l10n.showRawOcrText,
          ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _confirmAndReturn,
            tooltip: l10n.confirmData,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addManualDog,
        icon: const Icon(Icons.add),
        label: Text(l10n.addDogLabel),
      ),
      body: Column(
        children: [
          // Confidence indicator
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: _getConfidenceColor().withValues(alpha: 0.1),
            child: Row(
              children: [
                Icon(
                  _getConfidenceIcon(),
                  color: _getConfidenceColor(),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.accuracyPercent('${(widget.scanResult.confidence * 100).toStringAsFixed(0)}%'),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _getConfidenceColor(),
                        ),
                      ),
                      Text(
                        l10n.dogsFoundTapToEdit(_editableDogs.length),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Raw OCR text (expandable)
          if (_showRawText && widget.scanResult.rawText != null)
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxHeight: 200),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                    child: Row(
                      children: [
                        Icon(Icons.text_snippet, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 6),
                        Text(
                          l10n.rawOcrTextTitle,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(12),
                      child: SelectableText(
                        widget.scanResult.rawText!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // View: tree or list
          Expanded(
            child: _editableDogs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          l10n.noDogsFoundInScan,
                          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.tapToAddManually,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  )
                : _treeView
                    ? _buildPedigreeTreeView()
                    : Column(
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            color: theme.colorScheme.primary.withValues(alpha: 0.08),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, size: 18, color: theme.colorScheme.primary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    l10n.allFieldsEditable,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                              itemCount: _editableDogs.length,
                              itemBuilder: (context, index) {
                                final dog = _editableDogs[index];
                                return _buildDogCard(dog, index);
                              },
                            ),
                          ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildDogCard(ScannedDog dog, int index) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: dog.confidence > 0.8
                      ? Colors.green[100]
                      : Colors.orange[100],
                  child: Icon(
                    dog.gender == 'Male' ? Icons.male : Icons.female,
                    color: dog.confidence > 0.8
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
                          _positionLabel(dog.position!),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _editDog(dog, index),
                  tooltip: l10n.edit,
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: Colors.red[400]),
                  onPressed: () => _removeDog(index),
                  tooltip: l10n.delete,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (dog.registrationNumber != null)
              _buildInfoRow(l10n.regNoLabel, dog.registrationNumber!),
            if (dog.breed != null) _buildInfoRow('${l10n.breed}:', dog.breed!),
            if (dog.birthDate != null)
              _buildInfoRow(l10n.bornLabel, dog.birthDate!),
            if (dog.color != null) _buildInfoRow('${l10n.color}:', dog.color!),
            if (dog.gender != null)
              _buildInfoRow('${l10n.gender}:', dog.gender == 'Male' ? l10n.male : l10n.female),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: dog.confidence,
              backgroundColor: Colors.grey[200],
              color: dog.confidence > 0.8 ? Colors.green : Colors.orange,
            ),
            const SizedBox(height: 4),
            Text(
              l10n.confidencePercent('${(dog.confidence * 100).toStringAsFixed(0)}%'),
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
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
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
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
    if (widget.scanResult.confidence > 0.8) return AppColors.success;
    if (widget.scanResult.confidence > 0.6) return AppColors.warning;
    return AppColors.error;
  }

  IconData _getConfidenceIcon() {
    if (widget.scanResult.confidence > 0.8) return Icons.check_circle;
    if (widget.scanResult.confidence > 0.6) return Icons.warning;
    return Icons.error;
  }

  // ──────────────────────────────────────────────
  // Position label mapping (data key → localized display)
  // ──────────────────────────────────────────────

  String _positionLabel(String position) {
    final l10n = AppLocalizations.of(context)!;
    switch (position) {
      case 'Hovedhund': return l10n.mainDog;
      case 'Far': return l10n.sire;
      case 'Mor': return l10n.dam;
      case 'Farfar': return l10n.paternalGrandfather;
      case 'Farmor': return l10n.paternalGrandmother;
      case 'Morfar': return l10n.maternalGrandfather;
      case 'Mormor': return l10n.maternalGrandmother;
      case 'Farfars far': return l10n.greatGrandsirePP;
      case 'Farfars mor': return l10n.greatGrandamPP;
      case 'Farmors far': return l10n.greatGrandsirePM;
      case 'Farmors mor': return l10n.greatGrandamPM;
      case 'Morfars far': return l10n.greatGrandsireMP;
      case 'Morfars mor': return l10n.greatGrandamMP;
      case 'Mormors far': return l10n.greatGrandsireMM;
      case 'Mormors mor': return l10n.greatGrandamMM;
      // Generation 4
      case 'Farfars fars far': return l10n.gen4PGFSire;
      case 'Farfars fars mor': return l10n.gen4PGFDam;
      case 'Farfars mors far': return l10n.gen4PGMSire;
      case 'Farfars mors mor': return l10n.gen4PGMDam;
      case 'Farmors fars far': return l10n.gen4PMFSire;
      case 'Farmors fars mor': return l10n.gen4PMFDam;
      case 'Farmors mors far': return l10n.gen4PMMSire;
      case 'Farmors mors mor': return l10n.gen4PMMDam;
      case 'Morfars fars far': return l10n.gen4MGFSire;
      case 'Morfars fars mor': return l10n.gen4MGFDam;
      case 'Morfars mors far': return l10n.gen4MGMSire;
      case 'Morfars mors mor': return l10n.gen4MGMDam;
      case 'Mormors fars far': return l10n.gen4MMFSire;
      case 'Mormors fars mor': return l10n.gen4MMFDam;
      case 'Mormors mors far': return l10n.gen4MMMSire;
      case 'Mormors mors mor': return l10n.gen4MMMDam;
      default: return position;
    }
  }

  // ──────────────────────────────────────────────
  // Pedigree Tree View
  // ──────────────────────────────────────────────

  Widget _buildPedigreeTreeView() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Column 1: Main dog
              _buildTreeCard('Hovedhund', isMain: true),
              const SizedBox(width: 14),
              _buildTreeConnector(160),
              const SizedBox(width: 14),
              // Column 2: Parents
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTreeCard('Far'),
                  const SizedBox(height: 20),
                  _buildTreeCard('Mor'),
                ],
              ),
              const SizedBox(width: 14),
              _buildTreeConnector(320),
              const SizedBox(width: 14),
              // Column 3: Grandparents
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTreeCard('Farfar', small: true),
                  const SizedBox(height: 8),
                  _buildTreeCard('Farmor', small: true),
                  const SizedBox(height: 20),
                  _buildTreeCard('Morfar', small: true),
                  const SizedBox(height: 8),
                  _buildTreeCard('Mormor', small: true),
                ],
              ),
              const SizedBox(width: 14),
              _buildTreeConnector(520),
              const SizedBox(width: 14),
              // Column 4: Great-grandparents
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTreeCard('Farfars far', mini: true),
                  const SizedBox(height: 4),
                  _buildTreeCard('Farfars mor', mini: true),
                  const SizedBox(height: 10),
                  _buildTreeCard('Farmors far', mini: true),
                  const SizedBox(height: 4),
                  _buildTreeCard('Farmors mor', mini: true),
                  const SizedBox(height: 16),
                  _buildTreeCard('Morfars far', mini: true),
                  const SizedBox(height: 4),
                  _buildTreeCard('Morfars mor', mini: true),
                  const SizedBox(height: 10),
                  _buildTreeCard('Mormors far', mini: true),
                  const SizedBox(height: 4),
                  _buildTreeCard('Mormors mor', mini: true),
                ],
              ),
              const SizedBox(width: 10),
              _buildTreeConnector(900),
              const SizedBox(width: 10),
              // Column 5: Great-great-grandparents (gen 4)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTreeCard('Farfars fars far', mini: true),
                  const SizedBox(height: 2),
                  _buildTreeCard('Farfars fars mor', mini: true),
                  const SizedBox(height: 6),
                  _buildTreeCard('Farfars mors far', mini: true),
                  const SizedBox(height: 2),
                  _buildTreeCard('Farfars mors mor', mini: true),
                  const SizedBox(height: 10),
                  _buildTreeCard('Farmors fars far', mini: true),
                  const SizedBox(height: 2),
                  _buildTreeCard('Farmors fars mor', mini: true),
                  const SizedBox(height: 6),
                  _buildTreeCard('Farmors mors far', mini: true),
                  const SizedBox(height: 2),
                  _buildTreeCard('Farmors mors mor', mini: true),
                  const SizedBox(height: 14),
                  _buildTreeCard('Morfars fars far', mini: true),
                  const SizedBox(height: 2),
                  _buildTreeCard('Morfars fars mor', mini: true),
                  const SizedBox(height: 6),
                  _buildTreeCard('Morfars mors far', mini: true),
                  const SizedBox(height: 2),
                  _buildTreeCard('Morfars mors mor', mini: true),
                  const SizedBox(height: 10),
                  _buildTreeCard('Mormors fars far', mini: true),
                  const SizedBox(height: 2),
                  _buildTreeCard('Mormors fars mor', mini: true),
                  const SizedBox(height: 6),
                  _buildTreeCard('Mormors mors far', mini: true),
                  const SizedBox(height: 2),
                  _buildTreeCard('Mormors mors mor', mini: true),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTreeCard(
    String position, {
    bool isMain = false,
    bool small = false,
    bool mini = false,
  }) {
    final dog = _findByPosition(position);
    final width = mini ? 110.0 : (small ? 140.0 : (isMain ? 180.0 : 155.0));
    final height = mini ? 52.0 : (small ? 72.0 : (isMain ? 100.0 : 82.0));
    final fontSize = mini ? 10.0 : (small ? 11.0 : (isMain ? 14.0 : 12.0));
    final genderFromPosition = _genderForPosition(position);
    final effectiveGender = dog?.gender ?? genderFromPosition;
    final isFemaleCard = effectiveGender == 'Female';
    final posLabel = _positionLabel(position);

    if (dog == null) {
      return GestureDetector(
        onTap: () => _editOrAddAtPosition(position, genderFromPosition),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!mini) Text(
                  posLabel,
                  style: TextStyle(fontSize: fontSize - 2, color: Colors.grey[500]),
                ),
                Icon(Icons.add_circle_outline, size: mini ? 16 : 20, color: Colors.grey[400]),
                if (!mini) Text(
                  AppLocalizations.of(context)!.tapToAdd,
                  style: TextStyle(fontSize: fontSize - 3, color: Colors.grey[400]),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final bgColor = isFemaleCard ? Colors.pink[50] : Colors.blue[50];
    final borderColor = isFemaleCard ? Colors.pink[300]! : Colors.blue[300]!;
    final iconColor = isFemaleCard ? Colors.pink[700] : Colors.blue[700];
    final idx = _editableDogs.indexOf(dog);

    return GestureDetector(
      onTap: () => idx >= 0 ? _editDog(dog, idx) : null,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: isMain ? 2.5 : 1),
          boxShadow: isMain
              ? [BoxShadow(color: borderColor.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))]
              : null,
        ),
        padding: EdgeInsets.all(mini ? 4 : 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!mini) Text(
              posLabel,
              style: TextStyle(fontSize: fontSize - 3, color: iconColor, fontWeight: FontWeight.w500),
            ),
            Row(
              children: [
                Icon(
                  isFemaleCard ? Icons.female : Icons.male,
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
                Icon(Icons.edit, size: mini ? 10 : 14, color: Colors.grey[400]),
              ],
            ),
            if (!mini && dog.registrationNumber != null)
              Text(
                dog.registrationNumber!,
                style: TextStyle(fontSize: fontSize - 3, color: Colors.grey[600]),
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTreeConnector(double height) {
    return Container(
      width: 2,
      height: height,
      color: Colors.grey[300],
    );
  }

  void _removeDog(int index) {
    setState(() {
      _editableDogs.removeAt(index);
    });
  }

  void _editDog(ScannedDog dog, int index, {bool removeOnCancel = false}) {
    final l10n = AppLocalizations.of(context)!;
    // Valid position values for the dropdown
    const validPositions = [
      'Hovedhund', 'Far', 'Mor',
      'Farfar', 'Farmor', 'Morfar', 'Mormor',
      'Farfars far', 'Farfars mor', 'Farmors far', 'Farmors mor',
      'Morfars far', 'Morfars mor', 'Mormors far', 'Mormors mor',
      // Generation 4
      'Farfars fars far', 'Farfars fars mor', 'Farfars mors far', 'Farfars mors mor',
      'Farmors fars far', 'Farmors fars mor', 'Farmors mors far', 'Farmors mors mor',
      'Morfars fars far', 'Morfars fars mor', 'Morfars mors far', 'Morfars mors mor',
      'Mormors fars far', 'Mormors fars mor', 'Mormors mors far', 'Mormors mors mor',
    ];

    final nameCtrl = TextEditingController(text: dog.name != 'Ukjent' ? dog.name : '');
    final regCtrl = TextEditingController(text: dog.registrationNumber ?? '');
    final breedCtrl = TextEditingController(text: dog.breed ?? '');
    final birthCtrl = TextEditingController(text: dog.birthDate ?? '');
    final colorCtrl = TextEditingController(text: dog.color ?? '');
    String? selectedGender = dog.gender;
    // Ensure gender matches dropdown values
    if (selectedGender != null && selectedGender != 'Male' && selectedGender != 'Female') {
      selectedGender = null;
    }
    // Ensure position matches dropdown values — prevents assertion crash
    String? selectedPosition = dog.position;
    if (selectedPosition != null && !validPositions.contains(selectedPosition)) {
      selectedPosition = null;
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l10n.editDog),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: l10n.name,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: regCtrl,
                  decoration: InputDecoration(
                    labelText: l10n.regNo,
                    border: const OutlineInputBorder(),
                    hintText: l10n.regNoHint,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: breedCtrl,
                  decoration: InputDecoration(
                    labelText: l10n.breed,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: birthCtrl,
                  decoration: InputDecoration(
                    labelText: l10n.birthDateLabel,
                    border: const OutlineInputBorder(),
                    hintText: l10n.dateFormatHint,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: colorCtrl,
                  decoration: InputDecoration(
                    labelText: l10n.color,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: ValueKey('gender_$selectedGender'),
                  initialValue: selectedGender,
                  decoration: InputDecoration(
                    labelText: l10n.gender,
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(value: 'Male', child: Text(l10n.male)),
                    DropdownMenuItem(value: 'Female', child: Text(l10n.female)),
                  ],
                  onChanged: (v) => setDialogState(() => selectedGender = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: ValueKey('pos_$selectedPosition'),
                  initialValue: selectedPosition,
                  decoration: InputDecoration(
                    labelText: l10n.positionInPedigree,
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(value: 'Hovedhund', child: Text(l10n.mainDog)),
                    DropdownMenuItem(value: 'Far', child: Text(l10n.sire)),
                    DropdownMenuItem(value: 'Mor', child: Text(l10n.dam)),
                    DropdownMenuItem(value: 'Farfar', child: Text(l10n.paternalGrandfather)),
                    DropdownMenuItem(value: 'Farmor', child: Text(l10n.paternalGrandmother)),
                    DropdownMenuItem(value: 'Morfar', child: Text(l10n.maternalGrandfather)),
                    DropdownMenuItem(value: 'Mormor', child: Text(l10n.maternalGrandmother)),
                    DropdownMenuItem(value: 'Farfars far', child: Text(l10n.greatGrandsirePP)),
                    DropdownMenuItem(value: 'Farfars mor', child: Text(l10n.greatGrandamPP)),
                    DropdownMenuItem(value: 'Farmors far', child: Text(l10n.greatGrandsirePM)),
                    DropdownMenuItem(value: 'Farmors mor', child: Text(l10n.greatGrandamPM)),
                    DropdownMenuItem(value: 'Morfars far', child: Text(l10n.greatGrandsireMP)),
                    DropdownMenuItem(value: 'Morfars mor', child: Text(l10n.greatGrandamMP)),
                    DropdownMenuItem(value: 'Mormors far', child: Text(l10n.greatGrandsireMM)),
                    DropdownMenuItem(value: 'Mormors mor', child: Text(l10n.greatGrandamMM)),
                    // Generation 4
                    DropdownMenuItem(value: 'Farfars fars far', child: Text(l10n.gen4PGFSire)),
                    DropdownMenuItem(value: 'Farfars fars mor', child: Text(l10n.gen4PGFDam)),
                    DropdownMenuItem(value: 'Farfars mors far', child: Text(l10n.gen4PGMSire)),
                    DropdownMenuItem(value: 'Farfars mors mor', child: Text(l10n.gen4PGMDam)),
                    DropdownMenuItem(value: 'Farmors fars far', child: Text(l10n.gen4PMFSire)),
                    DropdownMenuItem(value: 'Farmors fars mor', child: Text(l10n.gen4PMFDam)),
                    DropdownMenuItem(value: 'Farmors mors far', child: Text(l10n.gen4PMMSire)),
                    DropdownMenuItem(value: 'Farmors mors mor', child: Text(l10n.gen4PMMDam)),
                    DropdownMenuItem(value: 'Morfars fars far', child: Text(l10n.gen4MGFSire)),
                    DropdownMenuItem(value: 'Morfars fars mor', child: Text(l10n.gen4MGFDam)),
                    DropdownMenuItem(value: 'Morfars mors far', child: Text(l10n.gen4MGMSire)),
                    DropdownMenuItem(value: 'Morfars mors mor', child: Text(l10n.gen4MGMDam)),
                    DropdownMenuItem(value: 'Mormors fars far', child: Text(l10n.gen4MMFSire)),
                    DropdownMenuItem(value: 'Mormors fars mor', child: Text(l10n.gen4MMFDam)),
                    DropdownMenuItem(value: 'Mormors mors far', child: Text(l10n.gen4MMMSire)),
                    DropdownMenuItem(value: 'Mormors mors mor', child: Text(l10n.gen4MMMDam)),
                  ],
                  onChanged: (v) => setDialogState(() => selectedPosition = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                // If this was a new placeholder dog, remove it on cancel
                if (removeOnCancel && index < _editableDogs.length) {
                  setState(() => _editableDogs.removeAt(index));
                }
                Navigator.pop(context);
              },
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                // Guard against stale index
                if (index < 0 || index >= _editableDogs.length) {
                  Navigator.pop(context);
                  return;
                }

                final oldDog = _editableDogs[index];
                final newDog = dog.copyWith(
                  name: nameCtrl.text.isNotEmpty ? nameCtrl.text : 'Ukjent',
                  registrationNumber: regCtrl.text.isNotEmpty ? regCtrl.text : ScannedDog.clear,
                  breed: breedCtrl.text.isNotEmpty ? breedCtrl.text : ScannedDog.clear,
                  birthDate: birthCtrl.text.isNotEmpty ? birthCtrl.text : ScannedDog.clear,
                  color: colorCtrl.text.isNotEmpty ? colorCtrl.text : ScannedDog.clear,
                  gender: selectedGender,
                  position: selectedPosition,
                  confidence: 1.0, // User-verified
                );
                
                // Record correction for learning if position or name changed
                if (oldDog.position != selectedPosition || oldDog.name != nameCtrl.text) {
                  final fragment = oldDog.name.isNotEmpty && oldDog.name != 'Ukjent' 
                      ? oldDog.name 
                      : oldDog.registrationNumber ?? '';
                  if (fragment.isNotEmpty) {
                    _scannerService.recordCorrection(
                      rawTextFragment: fragment,
                      correctedPosition: selectedPosition ?? 'Hovedhund',
                      correctedName: nameCtrl.text.isNotEmpty ? nameCtrl.text : null,
                    );
                  }
                }
                
                setState(() {
                  _editableDogs[index] = newDog;
                });
                Navigator.pop(context);
              },
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }

  void _addManualDog() {
    final newDog = ScannedDog(
      name: 'Ukjent',
      confidence: 1.0,
    );
    setState(() {
      _editableDogs.add(newDog);
    });
    // Immediately open edit dialog for the new dog
    _editDog(newDog, _editableDogs.length - 1);
  }

  void _openScannerSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ScannerSettingsScreen(),
      ),
    );
  }

  void _confirmAndReturn() {
    if (_editableDogs.isEmpty) {
      Navigator.pop(context, null);
      return;
    }

    // Find the dog marked as "Hovedhund", fallback to first
    final mainDog = _editableDogs.firstWhere(
      (d) => d.position == 'Hovedhund',
      orElse: () => _editableDogs.first,
    );
    final parents = _editableDogs
        .where((d) => d.position == 'Far' || d.position == 'Mor')
        .toList();

    final gen4Positions = [
      'Farfars fars far', 'Farfars fars mor', 'Farfars mors far', 'Farfars mors mor',
      'Farmors fars far', 'Farmors fars mor', 'Farmors mors far', 'Farmors mors mor',
      'Morfars fars far', 'Morfars fars mor', 'Morfars mors far', 'Morfars mors mor',
      'Mormors fars far', 'Mormors fars mor', 'Mormors mors far', 'Mormors mors mor',
    ];

    final updatedResult = PedigreeScanResult(
      confidence: widget.scanResult.confidence,
      dog: mainDog,
      parents: parents,
      grandparents: _editableDogs
          .where((d) => ['Farfar', 'Farmor', 'Morfar', 'Mormor'].contains(d.position))
          .toList(),
      greatGrandparents: _editableDogs
          .where((d) => [
            'Farfars far', 'Farfars mor', 'Farmors far', 'Farmors mor',
            'Morfars far', 'Morfars mor', 'Mormors far', 'Mormors mor',
          ].contains(d.position))
          .toList(),
      greatGreatGrandparents: _editableDogs
          .where((d) => gen4Positions.contains(d.position))
          .toList(),
      rawText: widget.scanResult.rawText,
    );

    Navigator.pop(context, updatedResult);
  }
}

/// Settings screen for configuring scanner keywords and viewing learning data
class ScannerSettingsScreen extends StatefulWidget {
  const ScannerSettingsScreen({super.key});

  @override
  State<ScannerSettingsScreen> createState() => _ScannerSettingsScreenState();
}

class _ScannerSettingsScreenState extends State<ScannerSettingsScreen> {
  final PedigreeScannerService _service = PedigreeScannerService();
  
  List<String> _mainDogCustom = [];
  List<String> _sireCustom = [];
  List<String> _damCustom = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _mainDogCustom = await _service.getCustomKeywords('main_dog');
    _sireCustom = await _service.getCustomKeywords('sire');
    _damCustom = await _service.getCustomKeywords('dam');
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _saveSettings() async {
    await _service.setCustomKeywords('main_dog', _mainDogCustom);
    await _service.setCustomKeywords('sire', _sireCustom);
    await _service.setCustomKeywords('dam', _damCustom);
    if (mounted) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.settingsSaved), backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.scannerSettings),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSettings,
            tooltip: l10n.save,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ──── Cloud AI Scanner Info ────
                Card(
                  color: Colors.green[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.cloud_done, color: Colors.green[700]),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                l10n.geminiAiVision,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(l10n.cloudPowered, style: TextStyle(fontSize: 11, color: Colors.green[800], fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.scannerGeminiDescription,
                          style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Explanation card
                Card(
                  color: Colors.blue[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.lightbulb_outline, color: Colors.blue[700]),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                l10n.customizeScanner,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.addKeywordsDescription,
                          style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Main dog keywords
                _buildKeywordSection(
                  title: l10n.mainDogKeywords,
                  subtitle: l10n.wordsIdentifyMainDog,
                  defaultKeywords: [
                    'stamtavle for', 'pedigree of', 'hund:', 'dog:', 'navn:', 'name:',
                  ],
                  customKeywords: _mainDogCustom,
                  onAdd: (kw) => setState(() => _mainDogCustom.add(kw)),
                  onRemove: (index) => setState(() => _mainDogCustom.removeAt(index)),
                ),
                const SizedBox(height: 16),

                // Sire keywords
                _buildKeywordSection(
                  title: l10n.sireKeywords,
                  subtitle: l10n.wordsIdentifySire,
                  defaultKeywords: [
                    'far:', 'sire:', 'father:', 'hannhund', 'fader:',
                  ],
                  customKeywords: _sireCustom,
                  onAdd: (kw) => setState(() => _sireCustom.add(kw)),
                  onRemove: (index) => setState(() => _sireCustom.removeAt(index)),
                ),
                const SizedBox(height: 16),

                // Dam keywords
                _buildKeywordSection(
                  title: l10n.damKeywords,
                  subtitle: l10n.wordsIdentifyDam,
                  defaultKeywords: [
                    'mor:', 'dam:', 'mother:', 'tispe', 'moder:',
                  ],
                  customKeywords: _damCustom,
                  onAdd: (kw) => setState(() => _damCustom.add(kw)),
                  onRemove: (index) => setState(() => _damCustom.removeAt(index)),
                ),

                const SizedBox(height: 24),

                // Spatial parsing info
                Card(
                  color: Colors.green[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.auto_fix_high, color: Colors.green[700]),
                            const SizedBox(width: 8),
                            Text(
                              l10n.automaticLearning,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.automaticLearningDescription,
                          style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _clearLearningData,
                          icon: const Icon(Icons.delete_outline, size: 18),
                          label: Text(l10n.resetLearningData),
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildKeywordSection({
    required String title,
    required String subtitle,
    required List<String> defaultKeywords,
    required List<String> customKeywords,
    required Function(String) onAdd,
    required Function(int) onRemove,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            const SizedBox(height: 12),
            
            // Default keywords (read-only)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: defaultKeywords.map((kw) => Chip(
                label: Text(kw, style: const TextStyle(fontSize: 12)),
                backgroundColor: Colors.grey[200],
                visualDensity: VisualDensity.compact,
              )).toList(),
            ),
            
            if (customKeywords.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 4),
              Text(AppLocalizations.of(context)!.yourCustomKeywords, 
                style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: List.generate(customKeywords.length, (i) => Chip(
                  label: Text(customKeywords[i], style: const TextStyle(fontSize: 12)),
                  backgroundColor: Colors.blue[100],
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () => onRemove(i),
                  visualDensity: VisualDensity.compact,
                )),
              ),
            ],
            
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _KeywordInput(onSubmit: onAdd),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _clearLearningData() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.resetLearningDataTitle),
        content: Text(l10n.resetLearningDataBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n.resetAction),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      final box = await Hive.openBox('scanner_settings');
      await box.delete('corrections');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.learningDataReset), backgroundColor: Colors.orange),
        );
      }
    }
  }
}

/// Simple input widget for adding keywords
class _KeywordInput extends StatefulWidget {
  final Function(String) onSubmit;
  const _KeywordInput({required this.onSubmit});

  @override
  State<_KeywordInput> createState() => _KeywordInputState();
}

class _KeywordInputState extends State<_KeywordInput> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim().toLowerCase();
    if (text.isNotEmpty) {
      widget.onSubmit(text);
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return TextField(
      controller: _controller,
      decoration: InputDecoration(
        hintText: l10n.newKeywordHint,
        isDense: true,
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: const Icon(Icons.add_circle),
          onPressed: _submit,
        ),
      ),
      onSubmitted: (_) => _submit(),
    );
  }
}
