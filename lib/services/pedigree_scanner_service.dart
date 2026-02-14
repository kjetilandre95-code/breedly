import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Service for scanning and parsing pedigree documents
/// Uses Firebase Cloud Function → Gemini Vision AI (server-side)
class PedigreeScannerService {
  final ImagePicker _picker = ImagePicker();
  final HttpsCallable _scanFunction = FirebaseFunctions.instance.httpsCallable(
    'scanPedigree',
    options: HttpsCallableOptions(timeout: const Duration(seconds: 60)),
  );

  /// User-configurable scan settings stored in Hive
  static const String _settingsBoxName = 'scanner_settings';

  // ──────────────────────────────────────────────
  // Settings / Learning API
  // ──────────────────────────────────────────────

  /// Get the settings box (lazy open)
  Future<Box> _getSettingsBox() async {
    if (Hive.isBoxOpen(_settingsBoxName)) {
      return Hive.box(_settingsBoxName);
    }
    return await Hive.openBox(_settingsBoxName);
  }

  /// Get user-defined custom keywords for a given field
  Future<List<String>> getCustomKeywords(String field) async {
    final box = await _getSettingsBox();
    final saved = box.get('custom_keywords_$field');
    if (saved != null) {
      return List<String>.from(jsonDecode(saved));
    }
    return [];
  }

  /// Save user-defined custom keywords for a given field
  Future<void> setCustomKeywords(String field, List<String> keywords) async {
    final box = await _getSettingsBox();
    await box.put('custom_keywords_$field', jsonEncode(keywords));
  }

  /// Get all default + custom keywords for main dog name label
  Future<List<String>> getMainDogKeywords() async {
    final defaults = [
      // The label that precedes the dog's name on the pedigree
      'name:', 'name ', 'navn:', 'navn ', 'nimi:', 'nimi ',
      'namn:', 'namn ',  // Swedish
      'hund:', 'dog:',
      'stamtavle for', 'pedigree of', 'pedigree for',
      'sukutaulu', // Finnish "pedigree"
    ];
    final custom = await getCustomKeywords('main_dog');
    return [...defaults, ...custom];
  }

  /// Get all default + custom keywords for sire detection
  Future<List<String>> getSireKeywords() async {
    final defaults = [
      'far:', 'sire:', 'far ', 'father:', 'hannhund',
      'fader:', 'fader ', 'hanhund', 'hane:', 'isä:',
    ];
    final custom = await getCustomKeywords('sire');
    return [...defaults, ...custom];
  }

  /// Get all default + custom keywords for dam detection
  Future<List<String>> getDamKeywords() async {
    final defaults = [
      'mor:', 'dam:', 'mor ', 'mother:', 'tispe',
      'moder:', 'moder ', 'tik:', 'tikk:', 'emä:',
    ];
    final custom = await getCustomKeywords('dam');
    return [...defaults, ...custom];
  }

  /// Record a user correction for learning
  /// Stores patterns that associate text fragments with positions
  Future<void> recordCorrection({
    required String rawTextFragment,
    required String correctedPosition,
    required String? correctedName,
  }) async {
    final box = await _getSettingsBox();
    final corrections = box.get('corrections', defaultValue: '[]');
    final list = List<Map<String, dynamic>>.from(jsonDecode(corrections));
    
    list.add({
      'fragment': rawTextFragment.toLowerCase(),
      'position': correctedPosition,
      'name': correctedName,
      'timestamp': DateTime.now().toIso8601String(),
    });

    // Keep max 50 most recent corrections
    if (list.length > 50) {
      list.removeRange(0, list.length - 50);
    }

    await box.put('corrections', jsonEncode(list));
  }

  // ──────────────────────────────────────────────
  // Scanning (via Firebase Cloud Function)
  // ──────────────────────────────────────────────

  /// Scan pedigree from camera or gallery
  Future<PedigreeScanResult?> scanPedigree({
    required PedigreeScanSource source,
  }) async {
    try {
      XFile? image;
      
      switch (source) {
        case PedigreeScanSource.camera:
          image = await _picker.pickImage(
            source: ImageSource.camera,
            imageQuality: 85,
          );
          break;
        case PedigreeScanSource.gallery:
          image = await _picker.pickImage(
            source: ImageSource.gallery,
            imageQuality: 85,
          );
          break;
      }

      if (image == null) return null;

      final imageFile = File(image.path);
      debugPrint('Image picked: ${imageFile.path}');
      final imageBytes = await imageFile.readAsBytes();
      debugPrint('Image size: ${imageBytes.length} bytes');

      // Encode image to base64 for the Cloud Function
      final base64Image = base64Encode(imageBytes);
      debugPrint('Calling Cloud Function scanPedigree...');

      try {
        final response = await _scanFunction.call({
          'imageBase64': base64Image,
        });

        // Firebase returns Map<Object?, Object?> — convert via JSON roundtrip
        final raw = response.data;
        debugPrint('Cloud Function response type: ${raw.runtimeType}');
        final data = jsonDecode(jsonEncode(raw)) as Map<String, dynamic>;
        debugPrint('Cloud Function response keys: ${data.keys.toList()}');

        // Cloud Function returns {success, data, rawText}
        Map<String, dynamic> pedigreeJson;
        String rawText;

        if (data.containsKey('data') && data['data'] is Map) {
          pedigreeJson = Map<String, dynamic>.from(data['data'] as Map);
          rawText = data['rawText'] as String? ?? jsonEncode(pedigreeJson);
        } else if (data.containsKey('main_dog')) {
          pedigreeJson = Map<String, dynamic>.from(data);
          rawText = jsonEncode(pedigreeJson);
        } else {
          debugPrint('Unexpected response format: $data');
          return PedigreeScanResult(
            confidence: 0.0,
            dog: null,
            parents: [],
            grandparents: [],
            greatGrandparents: [],
            rawText: 'Uventet svar fra server. Nøkler: ${data.keys.toList()}',
          );
        }

        debugPrint('Parsed pedigree JSON keys: ${pedigreeJson.keys.toList()}');
        return _geminiJsonToResult(pedigreeJson, rawText);
      } on FirebaseFunctionsException catch (e) {
        debugPrint('Cloud Function error: ${e.code} - ${e.message}');
        String errorMsg;
        switch (e.code) {
          case 'unauthenticated':
            errorMsg = 'Du må være logget inn for å skanne.';
            break;
          case 'resource-exhausted':
            errorMsg = 'For mange skanninger. Prøv igjen senere.';
            break;
          default:
            errorMsg = e.message ?? 'Ukjent serverfeil (${e.code})';
        }
        return PedigreeScanResult(
          confidence: 0.0,
          dog: null,
          parents: [],
          grandparents: [],
          greatGrandparents: [],
          rawText: 'Feil: $errorMsg',
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Error scanning pedigree: $e');
      debugPrint('Stack trace: $stackTrace');
      return PedigreeScanResult(
        confidence: 0.0,
        dog: null,
        parents: [],
        grandparents: [],
        greatGrandparents: [],
        rawText: 'Feil ved skanning: $e',
      );
    }
  }

  void dispose() {
    // No resources to release
  }

  /// Normalize gender strings from Gemini to exactly 'Male' or 'Female'
  static String? _normalizeGender(String? raw) {
    if (raw == null) return null;
    final lower = raw.toLowerCase().trim();
    if (lower == 'male' || lower == 'hann' || lower == 'hannhund' || lower == 'han' || lower == 'hane') {
      return 'Male';
    }
    if (lower == 'female' || lower == 'tispe' || lower == 'tik' || lower == 'tikk' || lower == 'hona') {
      return 'Female';
    }
    return null; // Unknown gender — leave unset rather than crash
  }

  // ──────────────────────────────────────────────
  // JSON → PedigreeScanResult mapping
  // ──────────────────────────────────────────────

  // ignore: unintended_html_in_doc_comment
  /// Safely convert any Map to Map<String, dynamic>
  static Map<String, dynamic>? _toMap(dynamic value) {
    if (value == null) return null;
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  PedigreeScanResult _geminiJsonToResult(Map<String, dynamic> json, String rawText) {
    ScannedDog? mainDog;
    final parents = <ScannedDog>[];
    final grandparents = <ScannedDog>[];

    // Main dog
    final mainJson = _toMap(json['main_dog']);
    if (mainJson != null) {
      final name = mainJson['name'] as String?;
      if (name != null && name.isNotEmpty) {
        mainDog = ScannedDog(
          name: name,
          registrationNumber: mainJson['registration_number'] as String?,
          breed: mainJson['breed'] as String?,
          birthDate: mainJson['birth_date'] as String?,
          color: mainJson['color'] as String?,
          gender: _normalizeGender(mainJson['gender'] as String?),
          confidence: 0.95,
          position: 'Hovedhund',
        );
      }
    }

    // Sire
    final sireJson = _toMap(json['sire']);
    if (sireJson != null && sireJson['name'] != null) {
      parents.add(ScannedDog(
        name: sireJson['name'] as String,
        registrationNumber: sireJson['registration_number'] as String?,
        breed: sireJson['breed'] as String?,
        birthDate: sireJson['birth_date'] as String?,
        gender: 'Male',
        confidence: 0.9,
        position: 'Far',
      ));
    }

    // Dam
    final damJson = _toMap(json['dam']);
    if (damJson != null && damJson['name'] != null) {
      parents.add(ScannedDog(
        name: damJson['name'] as String,
        registrationNumber: damJson['registration_number'] as String?,
        breed: damJson['breed'] as String?,
        birthDate: damJson['birth_date'] as String?,
        gender: 'Female',
        confidence: 0.9,
        position: 'Mor',
      ));
    }

    // Grandparents
    _addAncestor(json, 'paternal_grandfather', 'Farfar', 'Male', grandparents);
    _addAncestor(json, 'paternal_grandmother', 'Farmor', 'Female', grandparents);
    _addAncestor(json, 'maternal_grandfather', 'Morfar', 'Male', grandparents);
    _addAncestor(json, 'maternal_grandmother', 'Mormor', 'Female', grandparents);

    // Great-grandparents (3rd generation)
    final greatGrandparents = <ScannedDog>[];
    _addAncestor(json, 'paternal_gf_father', 'Farfars far', 'Male', greatGrandparents);
    _addAncestor(json, 'paternal_gf_mother', 'Farfars mor', 'Female', greatGrandparents);
    _addAncestor(json, 'paternal_gm_father', 'Farmors far', 'Male', greatGrandparents);
    _addAncestor(json, 'paternal_gm_mother', 'Farmors mor', 'Female', greatGrandparents);
    _addAncestor(json, 'maternal_gf_father', 'Morfars far', 'Male', greatGrandparents);
    _addAncestor(json, 'maternal_gf_mother', 'Morfars mor', 'Female', greatGrandparents);
    _addAncestor(json, 'maternal_gm_father', 'Mormors far', 'Male', greatGrandparents);
    _addAncestor(json, 'maternal_gm_mother', 'Mormors mor', 'Female', greatGrandparents);

    double confidence = 0.0;
    if (mainDog != null) confidence += 0.4;
    if (parents.isNotEmpty) confidence += 0.3;
    if (parents.length >= 2) confidence += 0.15;
    if (grandparents.isNotEmpty) confidence += 0.15;

    return PedigreeScanResult(
      confidence: confidence.clamp(0.0, 1.0),
      dog: mainDog,
      parents: parents,
      grandparents: grandparents,
      greatGrandparents: greatGrandparents,
      rawText: rawText,
    );
  }

  void _addAncestor(
    Map<String, dynamic> json, 
    String key, 
    String position, 
    String gender,
    List<ScannedDog> list,
  ) {
    final gpJson = _toMap(json[key]);
    if (gpJson != null && gpJson['name'] != null) {
      final name = gpJson['name'] as String;
      if (name.isNotEmpty) {
        list.add(ScannedDog(
          name: name,
          registrationNumber: gpJson['registration_number'] as String?,
          gender: gender,
          confidence: 0.85,
          position: position,
        ));
      }
    }
  }
}

enum PedigreeScanSource {
  camera,
  gallery,
}

/// Result from scanning a pedigree document
class PedigreeScanResult {
  /// Confidence score (0.0 to 1.0)
  final double confidence;
  
  /// Main dog information
  final ScannedDog? dog;
  
  /// Parents (should be 2)
  final List<ScannedDog> parents;
  
  /// Grandparents (should be 4)
  final List<ScannedDog> grandparents;
  
  /// Great-grandparents (should be 8)
  final List<ScannedDog> greatGrandparents;

  /// Raw OCR text from the scan
  final String? rawText;

  PedigreeScanResult({
    required this.confidence,
    required this.dog,
    required this.parents,
    required this.grandparents,
    required this.greatGrandparents,
    this.rawText,
  });

  /// Total number of dogs extracted
  int get totalDogs =>
      (dog != null ? 1 : 0) +
      parents.length +
      grandparents.length +
      greatGrandparents.length;

  /// Whether the scan was successful
  bool get isSuccessful => confidence > 0.7 && dog != null;
}

/// Scanned dog information from pedigree
class ScannedDog {
  final String name;
  final String? registrationNumber;
  final String? breed;
  final String? birthDate;
  final String? gender;
  final String? color;
  final double confidence;
  
  /// Position in pedigree (e.g., "father", "mother", "paternal_grandfather")
  final String? position;

  ScannedDog({
    required this.name,
    this.registrationNumber,
    this.breed,
    this.birthDate,
    this.gender,
    this.color,
    required this.confidence,
    this.position,
  });

  /// Use `_sentinel` to explicitly clear a nullable field:
  /// `copyWith(breed: ScannedDog.clear)` sets breed to null
  static const String _clearSentinel = '__CLEAR__';
  static const String clear = _clearSentinel;

  ScannedDog copyWith({
    String? name,
    String? registrationNumber,
    String? breed,
    String? birthDate,
    String? gender,
    String? color,
    double? confidence,
    String? position,
  }) {
    return ScannedDog(
      name: name ?? this.name,
      registrationNumber: registrationNumber == _clearSentinel ? null : (registrationNumber ?? this.registrationNumber),
      breed: breed == _clearSentinel ? null : (breed ?? this.breed),
      birthDate: birthDate == _clearSentinel ? null : (birthDate ?? this.birthDate),
      gender: gender == _clearSentinel ? null : (gender ?? this.gender),
      color: color == _clearSentinel ? null : (color ?? this.color),
      confidence: confidence ?? this.confidence,
      position: position == _clearSentinel ? null : (position ?? this.position),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'registrationNumber': registrationNumber,
      'breed': breed,
      'birthDate': birthDate,
      'gender': gender,
      'color': color,
      'confidence': confidence,
      'position': position,
    };
  }
}
