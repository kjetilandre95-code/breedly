import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:breedly/models/show_result.dart';
import 'package:breedly/services/auth_service.dart';
import 'dart:math' as math;

/// Service for shared judge names and show names across all users.
/// Data is stored in a global Firebase collection so all users benefit.
class ShowDataService {
  static final ShowDataService _instance = ShowDataService._internal();
  factory ShowDataService() => _instance;
  ShowDataService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ──── FUZZY STRING MATCHING ────

  /// Levenshtein distance between two strings
  static int levenshtein(String a, String b) {
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    final la = a.length;
    final lb = b.length;

    // Use two rows instead of full matrix for memory efficiency
    var prev = List<int>.generate(lb + 1, (i) => i);
    var curr = List<int>.filled(lb + 1, 0);

    for (int i = 1; i <= la; i++) {
      curr[0] = i;
      for (int j = 1; j <= lb; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        curr[j] = [
          prev[j] + 1,        // deletion
          curr[j - 1] + 1,    // insertion
          prev[j - 1] + cost, // substitution
        ].reduce(math.min);
      }
      final tmp = prev;
      prev = curr;
      curr = tmp;
    }

    return prev[lb];
  }

  /// Normalized similarity between 0.0 (different) and 1.0 (identical)
  static double similarity(String a, String b) {
    if (a.isEmpty && b.isEmpty) return 1.0;
    final maxLen = math.max(a.length, b.length);
    if (maxLen == 0) return 1.0;
    return 1.0 - (levenshtein(a, b) / maxLen);
  }

  /// Normalize a name for comparison: lowercase, trim, collapse whitespace,
  /// normalize accents (è→e, é→e, etc.), remove dots/commas
  static String _normalizeName(String name) {
    var n = name.toLowerCase().trim();
    // Collapse whitespace
    n = n.replaceAll(RegExp(r'\s+'), ' ');
    // Normalize common accent variations (keep æøå as they are distinct letters)
    n = n.replaceAll(RegExp(r'[éèêë]'), 'e');
    n = n.replaceAll(RegExp(r'[áàâã]'), 'a');
    n = n.replaceAll(RegExp(r'[íìîï]'), 'i');
    n = n.replaceAll(RegExp(r'[óòôõ]'), 'o');
    n = n.replaceAll(RegExp(r'[úùûü]'), 'u');
    n = n.replaceAll(RegExp(r'[ýÿ]'), 'y');
    // Remove dots, commas (e.g., "Jr." → "Jr")
    n = n.replaceAll(RegExp(r'[.,]'), '');
    return n;
  }

  /// Find similar names from a list. Returns matches sorted by similarity (best first).
  /// Only returns names with similarity >= [threshold] (default 0.75).
  static List<SimilarNameMatch> findSimilarNames(
    String input,
    List<String> existing, {
    double threshold = 0.75,
  }) {
    if (input.trim().isEmpty) return [];
    final normalizedInput = _normalizeName(input);
    final matches = <SimilarNameMatch>[];

    for (final name in existing) {
      final normalizedName = _normalizeName(name);
      // Exact normalized match
      if (normalizedInput == normalizedName) {
        matches.add(SimilarNameMatch(name: name, similarity: 1.0, isExactNormalized: true));
        continue;
      }
      // Similarity check
      final sim = similarity(normalizedInput, normalizedName);
      if (sim >= threshold) {
        matches.add(SimilarNameMatch(name: name, similarity: sim, isExactNormalized: false));
      }
    }

    matches.sort((a, b) => b.similarity.compareTo(a.similarity));
    return matches;
  }

  /// Check if a name already exists (case-insensitive, accent-insensitive)
  static bool nameExistsNormalized(String input, List<String> existing) {
    final norm = _normalizeName(input);
    return existing.any((e) => _normalizeName(e) == norm);
  }

  // Cached data
  List<String> _cachedJudges = [];
  List<String> _cachedShowNames = [];
  DateTime? _lastJudgeFetch;
  DateTime? _lastShowNameFetch;
  static const _cacheDuration = Duration(hours: 1);

  // ──── JUDGES ────

  /// Get all judge names from shared database (cached)
  Future<List<String>> getJudgeNames() async {
    if (_cachedJudges.isNotEmpty &&
        _lastJudgeFetch != null &&
        DateTime.now().difference(_lastJudgeFetch!) < _cacheDuration) {
      return _cachedJudges;
    }

    try {
      final snapshot = await _firestore
          .collection('shared_judges')
          .orderBy('name')
          .get(const GetOptions(source: Source.serverAndCache));

      _cachedJudges = snapshot.docs
          .map((doc) => doc.data()['name'] as String? ?? '')
          .where((name) => name.isNotEmpty)
          .toList();
      _lastJudgeFetch = DateTime.now();
    } catch (e) {
      debugPrint('Error fetching judges: $e');
      // Fall back to local data
      _cachedJudges = _getLocalJudgeNames();
    }

    return _cachedJudges;
  }

  /// Add a judge name to the shared database.
  /// If a normalized-equivalent name already exists, uses that instead.
  /// Returns the canonical name that was used (may differ from input if a match was found).
  Future<String> addJudgeName(String name) async {
    if (name.trim().isEmpty) return name;
    final trimmed = name.trim();

    // Check if an equivalent (normalized) name already exists in cache
    final existing = _cachedJudges.firstWhere(
      (e) => _normalizeName(e) == _normalizeName(trimmed),
      orElse: () => '',
    );

    // If exact normalized match exists, use that spelling and bump useCount
    final canonical = existing.isNotEmpty ? existing : trimmed;

    // Add to local cache if truly new
    if (!_cachedJudges.contains(canonical)) {
      _cachedJudges.add(canonical);
      _cachedJudges.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    }

    // Sync to Firebase — use normalized docId for deduplication
    try {
      final docId = _normalizeName(canonical).replaceAll(RegExp(r'[^a-z0-9æøåäöü]'), '_');
      await _firestore.collection('shared_judges').doc(docId).set({
        'name': canonical,
        'addedBy': AuthService().currentUserId ?? 'anonymous',
        'updatedAt': FieldValue.serverTimestamp(),
        'useCount': FieldValue.increment(1),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error adding judge: $e');
    }

    return canonical;
  }

  /// Get judge names from local Hive data (fallback)
  List<String> _getLocalJudgeNames() {
    try {
      final box = Hive.box<ShowResult>('show_results');
      final names = <String>{};
      for (final result in box.values) {
        if (result.judge != null && result.judge!.isNotEmpty) {
          names.add(result.judge!);
        }
        if (result.groupJudge != null && result.groupJudge!.isNotEmpty) {
          names.add(result.groupJudge!);
        }
        if (result.bisJudge != null && result.bisJudge!.isNotEmpty) {
          names.add(result.bisJudge!);
        }
      }
      final sorted = names.toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      return sorted;
    } catch (_) {
      return [];
    }
  }

  // ──── SHOW NAMES ────

  /// Get all show names from shared database (cached)
  Future<List<String>> getShowNames() async {
    if (_cachedShowNames.isNotEmpty &&
        _lastShowNameFetch != null &&
        DateTime.now().difference(_lastShowNameFetch!) < _cacheDuration) {
      return _cachedShowNames;
    }

    try {
      final snapshot = await _firestore
          .collection('shared_show_names')
          .orderBy('name')
          .get(const GetOptions(source: Source.serverAndCache));

      _cachedShowNames = snapshot.docs
          .map((doc) => doc.data()['name'] as String? ?? '')
          .where((name) => name.isNotEmpty)
          .toList();
      _lastShowNameFetch = DateTime.now();
    } catch (e) {
      debugPrint('Error fetching show names: $e');
      _cachedShowNames = _getLocalShowNames();
    }

    return _cachedShowNames;
  }

  /// Add a show name to the shared database.
  /// If a normalized-equivalent name already exists, uses that instead.
  Future<String> addShowName(String name) async {
    if (name.trim().isEmpty) return name;
    final trimmed = name.trim();

    // Check if an equivalent (normalized) name already exists in cache
    final existing = _cachedShowNames.firstWhere(
      (e) => _normalizeName(e) == _normalizeName(trimmed),
      orElse: () => '',
    );

    final canonical = existing.isNotEmpty ? existing : trimmed;

    if (!_cachedShowNames.contains(canonical)) {
      _cachedShowNames.add(canonical);
      _cachedShowNames.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    }

    try {
      final docId = _normalizeName(canonical).replaceAll(RegExp(r'[^a-z0-9æøåäöü]'), '_');
      await _firestore.collection('shared_show_names').doc(docId).set({
        'name': canonical,
        'addedBy': AuthService().currentUserId ?? 'anonymous',
        'updatedAt': FieldValue.serverTimestamp(),
        'useCount': FieldValue.increment(1),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error adding show name: $e');
    }

    return canonical;
  }

  /// Get show names from local Hive data (fallback)
  List<String> _getLocalShowNames() {
    try {
      final box = Hive.box<ShowResult>('show_results');
      final names = <String>{};
      for (final result in box.values) {
        if (result.showName.isNotEmpty) {
          names.add(result.showName);
        }
      }
      final sorted = names.toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      return sorted;
    } catch (_) {
      return [];
    }
  }

  // ──── BULK SYNC ────

  /// Upload all local judges and show names to shared database.
  /// Call this once for existing users to populate the database.
  Future<void> syncLocalDataToCloud() async {
    final localJudges = _getLocalJudgeNames();
    final localShowNames = _getLocalShowNames();

    for (final judge in localJudges) {
      await addJudgeName(judge);
    }
    for (final showName in localShowNames) {
      await addShowName(showName);
    }
  }

  /// Clear cache to force a fresh fetch
  void clearCache() {
    _cachedJudges = [];
    _cachedShowNames = [];
    _lastJudgeFetch = null;
    _lastShowNameFetch = null;
  }

  // ──── TITLE PROGRESSION ────

  /// Get the FCI group number (1-10) for a breed name. Returns null if unknown.
  static int? getFciGroup(String breed) {
    final b = breed.toLowerCase().trim();
    for (final entry in _breedToGroup.entries) {
      if (b.contains(entry.key.toLowerCase())) return entry.value;
    }
    return null;
  }

  /// Get additional requirements ("tilleggskrav") for NO UCH for a specific breed.
  /// Returns null if no additional requirements apply (groups 8, 9, 10, and most others).
  /// Based on NKK Championatregler gjeldende fra 01.01.2010.
  static NkkTilleggskrav? getTilleggskrav(String breed) {
    final b = breed.toLowerCase().trim();

    // ── GRUPPE 1 ──
    if (b.contains('australian kelpie')) {
      return NkkTilleggskrav(
        fciGroup: 1,
        breedName: breed,
        description: 'NKKs kåringsprøve – bestått, eller RIK: FCI-IGP1/FCI-SL1/FCI-IFH1, '
            'eller brukshundprøve D→C, eller godkjent modul 2 Norske Redningshunder.',
        kravType: 'Bruksprøve',
      );
    }
    if (b.contains('schäferhund') || b.contains('schaferhund')) {
      return NkkTilleggskrav(
        fciGroup: 1,
        breedName: breed,
        description: 'NKKs kåringsprøve – bestått, eller RIK: FCI-IGP1/FCI-SL1, '
            'eller brukshundprøve D→C.',
        kravType: 'Bruksprøve',
      );
    }

    // ── GRUPPE 2 ──
    if (b.contains('rottweiler')) {
      return NkkTilleggskrav(
        fciGroup: 2,
        breedName: breed,
        description: 'NKKs kåringsprøve – bestått, eller RIK: FCI-IGP1/FCI-SL1/FCI-IFH1, '
            'eller brukshundprøve D→C, eller godkjent modul 2 Norske Redningshunder.',
        kravType: 'Bruksprøve',
      );
    }
    if (b.contains('dobermann') || b.contains('doberman')) {
      return NkkTilleggskrav(
        fciGroup: 2,
        breedName: breed,
        description: 'Bestått ett av: NKKs kåringsprøve, Korning, FA, MH m/godkjent skudd, '
            'Ferdselsprøve, godkjent kl.D i NBF, ZTP, 1.premie blodspor AK, '
            '1.premie AG/Hopp kl.1, 1.premie smeller kl.1, 1.premie rallylydighet kl.1, '
            '1.premie lydighetsprøver kl.1, eller godkjent modul 2 Norske Redningshunder.',
        kravType: 'Bruksprøve/Mentaltest',
      );
    }

    // ── GRUPPE 3 ──
    if (b.contains('tysk jaktterrier')) {
      return NkkTilleggskrav(
        fciGroup: 3,
        breedName: breed,
        description: 'Resultat «Godkjent» på anleggsprøve for tysk jaktterrier, '
            'alternativt 2.premie på naturhi (overgangsordning t.o.m. 31.12.2027).',
        kravType: 'Jaktprøve',
      );
    }

    // ── GRUPPE 4 – Alle dachshunder ──
    if (b.contains('dachshund') || b.contains('dachs')) {
      return NkkTilleggskrav(
        fciGroup: 4,
        breedName: breed,
        description: '2× min. 2.premie for 2 forskjellige dommere på hiprøve, '
            'blodsporprøve eller drevprøve for dachshund i Norden.',
        kravType: 'Jaktprøve',
      );
    }

    // ── GRUPPE 5 ──
    if (b.contains('alaskan malamute')) {
      return NkkTilleggskrav(
        fciGroup: 5,
        breedName: breed,
        description: 'Bestått min. 1 av 5 deltester til NO TCH '
            '(Malamutetest 1, 2, 3, 4 eller 5).',
        kravType: 'Trekkhundprøve',
      );
    }
    if (b.contains('finsk spets') || b.contains('norrbottenspets')) {
      return NkkTilleggskrav(
        fciGroup: 5,
        breedName: breed,
        description: '1× min. 3.premie på jaktprøve for halsende fuglehund.',
        kravType: 'Jaktprøve',
      );
    }
    if (b.contains('hälleforshund') || b.contains('jämthund') ||
        b.contains('karelsk bjørnehund') || b.contains('karelsk bjørnhund') ||
        b.contains('laika') ||
        b.contains('norsk elghund grå') || b.contains('norsk elghund sort') ||
        b.contains('svensk hvit elghund')) {
      return NkkTilleggskrav(
        fciGroup: 5,
        breedName: breed,
        description: '1× 1.premie på jaktprøve for elghund (band-/løshund) i Norden.',
        kravType: 'Jaktprøve',
      );
    }
    if (b.contains('siberian husky')) {
      return NkkTilleggskrav(
        fciGroup: 5,
        breedName: breed,
        description: 'Min. 3.premie på trekkhundprøve for polare raser '
            '(nordisk stil, kort distanse, mellomdistanse eller langdistanse).',
        kravType: 'Trekkhundprøve',
      );
    }

    // ── GRUPPE 6 ──
    if (b.contains('bayersk viltsporhund') || b.contains('hannoveransk viltsporhund')) {
      return NkkTilleggskrav(
        fciGroup: 6,
        breedName: breed,
        description: 'Min. 1× 1.premie på blodsporprøve i Norge '
            'eller 1× 1.premie blodsporprøve i AK i Sverige.',
        kravType: 'Jaktprøve',
      );
    }
    if (b.contains('basset hound')) {
      return NkkTilleggskrav(
        fciGroup: 6,
        breedName: breed,
        description: 'Min. 3.premie på drevprøve for bassets eller blodsporprøve.',
        kravType: 'Jaktprøve',
      );
    }
    if (_isBassetBreed(b) && !b.contains('basset hound')) {
      return NkkTilleggskrav(
        fciGroup: 6,
        breedName: breed,
        description: 'Min. 2.premie på drevprøve for bassets.',
        kravType: 'Jaktprøve',
      );
    }
    if (b.contains('beagle') || b.contains('drever')) {
      return NkkTilleggskrav(
        fciGroup: 6,
        breedName: breed,
        description: '1× 1.premie på jaktprøve for drivende hunder (lovlig viltart for rasen).',
        kravType: 'Jaktprøve',
      );
    }
    if (_isStoever(b)) {
      return NkkTilleggskrav(
        fciGroup: 6,
        breedName: breed,
        description: '1× 1.premie på jaktprøve for drivende hunder (rev/hare for rasen).',
        kravType: 'Jaktprøve',
      );
    }

    // ── GRUPPE 7 – Stående fuglehunder ──
    // Most pointing dogs (except bracco italiano, drentsche patrijshond, 
    // gammel dansk hønsehund, italiensk spinone, stabyhoun)
    if (_isPointingDogWithKrav(b)) {
      return NkkTilleggskrav(
        fciGroup: 7,
        breedName: breed,
        description: '1× 1.premie i AK på jaktprøve for fuglehunder '
            '(høyfjell, lavland, skogsfugl eller tilsvarende). '
            'Alt: 2× cert + 1.premie i VK.',
        kravType: 'Jaktprøve',
      );
    }

    // Grupper 8, 9, 10 – ingen tilleggskrav for NO UCH
    return null;
  }

  static bool _isBassetBreed(String b) {
    return b.contains('basset') || b.contains('petit basset') || b.contains('grand basset');
  }

  static bool _isStoever(String b) {
    // Norwegian/Nordic støvere
    return b.contains('støver') || b.contains('dunker') || b.contains('haldenstøver') ||
        b.contains('hamiltonstøver') || b.contains('hygenhund') ||
        b.contains('schillerstøver') || b.contains('smålandsstøver') ||
        b.contains('gotlandsstøver') || b.contains('finsk støver');
  }

  static bool _isPointingDogWithKrav(String b) {
    // Exclude breeds without tilleggskrav
    if (b.contains('bracco italiano') || b.contains('drentsche patrijshond') ||
        b.contains('gammel dansk hønsehund') || b.contains('italiensk spinone') ||
        b.contains('stabijhoun') || b.contains('stabyhoun')) {
      return false;
    }
    // Check if it's a group 7 breed
    final group = getFciGroup(b);
    return group == 7;
  }

  /// Breed name → FCI group mapping (using lowercase partial match)
  static final Map<String, int> _breedToGroup = {
    // Gruppe 1
    'australian kelpie': 1, 'australian stumpy': 1, 'bearded collie': 1,
    'border collie': 1, 'bouvier': 1, 'briard': 1, 'chodsky': 1,
    'hvit gjeterhund': 1, 'old english sheepdog': 1, 'owczarek nizinny': 1,
    'romanian carpathian': 1, 'romanian mioritic': 1, 'schipperke': 1,
    'schäferhund': 1, 'schaferhund': 1, 'shetland sheepdog': 1,
    'welsh corgi': 1, 'belgisk fårehund': 1, 'collie': 1,
    'australian cattledog': 1, 'australian shepherd': 1, 'beauceron': 1,
    'bergamasco': 1, 'katalansk gjeterhund': 1, 'kroatisk gjeterhund': 1,
    'lancashire heeler': 1, 'mallorcansk gjeterhund': 1, 'maremma': 1,
    'miniature american shepherd': 1, 'picard': 1, 'owczarek podhalanski': 1,
    'portugisisk gjeterhund': 1, 'pyreneisk gjeterhund': 1,
    'schapendoes': 1, 'slovakisk cuvac': 1, 'sydrussisk ovtcharka': 1,
    'saarloos wolfhond': 1, 'vostochno': 1, 'komondor': 1, 'kuvasz': 1,
    'mudi': 1, 'puli': 1, 'pumi': 1, 'hollandsk gjeterhund': 1,
    // Gruppe 2
    'aidi': 2, 'azores cattledog': 2, 'boxer': 2, 'bullmastiff': 2,
    'castro laboreiro': 2, 'cimarron': 2, 'ciobanesc': 2, 'continental bulldog': 2,
    'dansk-svensk gårdshund': 2, 'dobermann': 2, 'doberman': 2,
    'engelsk bulldog': 2, 'engelsk mastiff': 2, 'grand danois': 2,
    'hovawart': 2, 'kangal': 2, 'karst gjeterhund': 2,
    'kaukasisk ovtcharka': 2, 'landseer': 2, 'leonberger': 2,
    'napolitansk mastiff': 2, 'newfoundlandshund': 2, 'presa canario': 2,
    'pyreneerhund': 2, 'pyreneisk mastiff': 2, 'rafeiro': 2,
    'rottweiler': 2, 'russisk sort terrier': 2, 'sarplaninac': 2,
    'sentralasiatisk ovtcharka': 2, 'serra da estrela': 2,
    'smoushond': 2, 'spansk mastiff': 2, 'tornjak': 2,
    'østerriksk pinscher': 2, 'appenzeller sennenhund': 2,
    'berner sennenhund': 2, 'entlebucher sennenhund': 2,
    'grosser schweizer sennenhund': 2, 'sankt bernhardshund': 2,
    'dvergschnauzer': 2, 'riesenschnauzer': 2, 'schnauzer': 2,
    'affenpinscher': 2, 'dvergpinscher': 2, 'pinscher': 2,
    'bordeaux dogge': 2, 'broholmer': 2, 'cane corso': 2,
    'perro dogo mallorquin': 2, 'shar pei': 2, 'tibetansk mastiff': 2,
    // Gruppe 3
    'amerikansk naken terrier': 3, 'biewer terrier': 3, 'rat terrier': 3,
    'tenterfield terrier': 3, 'toy fox terrier': 3, 'airedale terrier': 3,
    'bedlington terrier': 3, 'border terrier': 3, 'bull terrier': 3,
    'fox terrier': 3, 'irish softcoated': 3, 'irsk terrier': 3,
    'kerry blue terrier': 3, 'lakeland terrier': 3, 'manchester terrier': 3,
    'miniature bull terrier': 3, 'nihon teria': 3, 'parson russell terrier': 3,
    'staffordshire bull terrier': 3, 'terrier brasileiro': 3,
    'tysk jaktterrier': 3, 'welsh terrier': 3, 'australsk terrier': 3,
    'cairn terrier': 3, 'cesky terrier': 3, 'dandie dinmont terrier': 3,
    'irish glen of imaal': 3, 'jack russell terrier': 3, 'norfolk terrier': 3,
    'norwich terrier': 3, 'sealyham terrier': 3, 'skotsk terrier': 3,
    'skye terrier': 3, 'west highland white terrier': 3,
    'engelsk toy terrier': 3, 'silky terrier': 3, 'yorkshire terrier': 3,
    // Gruppe 4
    'dachshund': 4, 'dvergdachshund': 4, 'kanindachshund': 4,
    // Gruppe 5
    'american akita': 5, 'american eskimo dog': 5, 'basenji': 5,
    'canadian eskimo dog': 5, 'canaanhund': 5, 'chow chow': 5,
    'dansk spitz': 5, 'etnahund': 5, 'eurasier': 5, 'faraohund': 5,
    'finsk spets': 5, 'grosspitz': 5, 'islandsk fårehund': 5,
    'keeshond': 5, 'kintamani': 5, 'kleinspitz': 5, 'koreansk jindo': 5,
    'mittelspitz': 5, 'norrbottenspets': 5, 'norsk buhund': 5,
    'norsk lundehund': 5, 'peruviansk nakenhund': 5, 'podenco canario': 5,
    'podengo portugues': 5, 'pomeranian': 5, 'taiwan dog': 5,
    'thai bangkaew': 5, 'thai ridgeback': 5, 'volpino italiano': 5,
    'västgötaspets': 5, 'xoloitzcuintle': 5,
    'hälleforshund': 5, 'jämthund': 5, 'karelsk bjørnhund': 5,
    'norsk elghund grå': 5, 'norsk elghund sort': 5,
    'russisk europeisk laika': 5, 'svensk hvit elghund': 5,
    'vestsibirsk laika': 5, 'yakutian laika': 5, 'østsibirsk laika': 5,
    'alaskan malamute': 5, 'grønlandshund': 5, 'samojedhund': 5,
    'siberian husky': 5, 'finsk lapphund': 5, 'lapsk vallhund': 5,
    'svensk lapphund': 5, 'akita': 5, 'hokkaido': 5,
    'japansk spisshund': 5, 'kai': 5, 'kishu': 5, 'shiba': 5, 'shikoku': 5,
    'podenco ibicenco': 5,
    // Gruppe 6
    'amerikansk foxhound': 6, 'anglo-russisk støver': 6,
    'black and tan coonhound': 6, 'blodhund': 6, 'bluetick coonhound': 6,
    'brandlbracke': 6, 'dalmatiner': 6, 'estonian hound': 6, 'foxhound': 6,
    'harrier': 6, 'istarski': 6, 'otterhound': 6, 'plott': 6,
    'polish hunting dog': 6, 'rhodesian ridgeback': 6,
    'steiersk ruhåret bracke': 6, 'tiroler bracke': 6, 'tysk bracke': 6,
    'westfalsk dachsbracke': 6,
    'basset': 6, 'basset hound': 6, 'grand basset griffon vendeen': 6,
    'petit basset griffon vendeen': 6,
    'dunker': 6, 'finsk støver': 6, 'gotlandsstøver': 6,
    'haldenstøver': 6, 'hamiltonstøver': 6, 'hygenhund': 6,
    'schillerstøver': 6, 'smålandsstøver': 6,
    'alpinsk dachsbracke': 6, 'bayersk viltsporhund': 6,
    'hannoveransk viltsporhund': 6, 'beagle': 6, 'drever': 6,
    'ariégois': 6, 'artoishund': 6, 'balkanstøver': 6,
    'bernerstøver': 6, 'billy': 6, 'bosnisk': 6, 'briquet griffon': 6,
    'erdélyi kopo': 6, 'estlandsstøver': 6,
    'fransk hvit': 6, 'fransk trefarget': 6, 'gascon': 6,
    'grand bleu de gascogne': 6, 'grand griffon vendéen': 6,
    'gresk støver': 6, 'griffon bleu de gascogne': 6,
    'griffon fauve de bretagne': 6, 'griffon nivernais': 6,
    'italiensk korthåret støver': 6, 'italiensk strihåret støver': 6,
    'jugoslavisk': 6, 'jurastøver': 6,
    'liten anglo-fransk støver': 6, 'liten bernerstøver': 6,
    'liten jurastøver': 6, 'liten luzernerstøver': 6,
    'liten schweizerstøver': 6, 'luzernerstøver': 6,
    'petit bleu de gascogne': 6, 'poitevin': 6, 'polsk støver': 6,
    'porcelaine': 6, 'posavina': 6,
    'russisk flekket støver': 6, 'russisk støver': 6,
    'schweizerstøver': 6, 'slovakisk støver': 6,
    'slovensk bergstøver': 6, 'spansk støver': 6,
    'stor anglo-fransk': 6, 'treeing walker coonhound': 6,
    'beagle harrier': 6,
    // Gruppe 7
    'breton': 7, 'epagneul de saint-usuge': 7, 'grosser münsterländer': 7,
    'kleiner münsterländer': 7, 'vorstehhund': 7,
    'engelsk setter': 7, 'gordon setter': 7, 'irsk rød og hvit setter': 7,
    'irsk setter': 7, 'pointer': 7, 'blå picardie spaniel': 7,
    'bracco italiano': 7, 'braque': 7, 'drentsche patrijshond': 7,
    'fransk spaniel': 7, 'fransk vorstehhund': 7,
    'gammel dansk hønsehund': 7, 'italiensk spinone': 7,
    'perdiguero de burgos': 7, 'picard spaniel': 7,
    'pont-audemer spaniel': 7, 'portugisisk pointer': 7,
    'pudelpointer': 7, 'slovakisk vorstehhund': 7,
    'stabijhoun': 7, 'stabyhoun': 7, 'český fousek': 7,
    'ungarsk vizsla': 7, 'weimaraner': 7,
    // Gruppe 8
    'barbet': 8, 'kooikerhund': 8, 'lagotto romagnolo': 8,
    'portugisisk vannhund': 8, 'spansk vannhund': 8, 'wetterhoun': 8,
    'chesapeake bay retriever': 8, 'curly coated retriever': 8,
    'flat coated retriever': 8, 'golden retriever': 8,
    'labrador retriever': 8, 'nova scotia duck tolling retriever': 8,
    'amerikansk cocker spaniel': 8, 'amerikansk vannspaniel': 8,
    'clumber spaniel': 8, 'cocker spaniel': 8,
    'engelsk springer spaniel': 8, 'field spaniel': 8,
    'irsk vannspaniel': 8, 'sussex spaniel': 8,
    'wachtelhund': 8, 'welsh springer spaniel': 8,
    // Gruppe 9
    'bichon frisé': 9, 'bichon havanais': 9, 'bolognese': 9,
    'boston terrier': 9, 'cavalier king charles spaniel': 9,
    'chinese crested': 9, 'coton de tulear': 9, 'fransk bulldog': 9,
    'japanese chin': 9, 'king charles spaniel': 9, 'kromfohrländer': 9,
    'løwchen': 9, 'malteser': 9, 'mops': 9, 'papillon': 9,
    'pekingeser': 9, 'phalène': 9, 'prazsky krysarik': 9,
    'russian toy': 9, 'russisk tsvetnaya bolonka': 9,
    'dvergpuddel': 9, 'mellompuddel': 9, 'stor puddel': 9,
    'toy puddel': 9, 'griffon belge': 9, 'griffon bruxellois': 9,
    'petit brabancon': 9, 'chihuahua': 9, 'lhasa apso': 9,
    'shih tzu': 9, 'tibetansk spaniel': 9, 'tibetansk terrier': 9,
    // Gruppe 10
    'afghansk mynde': 10, 'azawakh': 10, 'borzoi': 10,
    'greyhound': 10, 'irsk ulvehund': 10, 'italiensk mynde': 10,
    'polsk mynde': 10, 'saluki': 10, 'skotsk hjortehund': 10,
    'sloughi': 10, 'spansk galgo': 10, 'ungarsk mynde': 10,
    'whippet': 10,
  };

  /// Calculate championship title progress for a dog based on official NKK rules.
  /// [dogDateOfBirth] is needed for age-based requirements (24 months for NO UCH).
  /// [dogBreed] is used to determine breed-specific additional requirements.
  TitleProgression getTitleProgression(List<ShowResult> results, {DateTime? dogDateOfBirth, String? dogBreed, bool tilleggskravCompleted = false}) {
    // ──── Certificate counting helpers ────
    bool hasCertType(ShowResult r, String certName) {
      if (r.certificates == null) return false;
      return r.certificates!.any((c) => c.toLowerCase() == certName.toLowerCase());
    }

    // ──── NO UCH (Norsk Utstillingschampionat) ────
    // Rules: 3x Cert from 3 different judges. At least 1 from NKK or equivalent.
    // At least 1 cert at age 24 months or later.
    int certCount = 0;
    final certJudges = <String>{};
    bool hasCertAfter24Months = false;

    for (final r in results) {
      if (hasCertType(r, 'Cert')) {
        certCount++;
        if (r.judge != null && r.judge!.isNotEmpty) {
          certJudges.add(r.judge!.toLowerCase());
        }
        if (dogDateOfBirth != null) {
          final ageAtShow = r.date.difference(dogDateOfBirth).inDays;
          if (ageAtShow >= 730) { // ~24 months
            hasCertAfter24Months = true;
          }
        } else {
          hasCertAfter24Months = true; // Unknown DOB, assume ok
        }
      }
    }
    final int certFromDiffJudges = certJudges.length.clamp(0, certCount);
    // The effective count is the minimum of certs and unique judges (need 3 unique judges)
    final int noUchProgress = certFromDiffJudges.clamp(0, 3);

    // ──── NO JrCH (Norsk Juniorchampionat) ────
    // Rules: 3x Junior Cert from 3 different judges at 3 different NKK shows
    int juniorCertCount = 0;
    final juniorCertJudges = <String>{};
    final juniorCertShows = <String>{};

    for (final r in results) {
      if (hasCertType(r, 'Junior Cert')) {
        juniorCertCount++;
        if (r.judge != null && r.judge!.isNotEmpty) {
          juniorCertJudges.add(r.judge!.toLowerCase());
        }
        juniorCertShows.add('${r.showName}_${r.date.toIso8601String()}'.toLowerCase());
      }
    }
    final int noJrChProgress = [juniorCertCount, juniorCertJudges.length, juniorCertShows.length].reduce((a, b) => a < b ? a : b).clamp(0, 3);

    // ──── NO VetCH (Norsk Veteranchampionat) ────
    // Rules: 3x Veteran Cert from 3 different judges at 3 different NKK shows
    int veteranCertCount = 0;
    final veteranCertJudges = <String>{};
    final veteranCertShows = <String>{};

    for (final r in results) {
      if (hasCertType(r, 'Veteran Cert')) {
        veteranCertCount++;
        if (r.judge != null && r.judge!.isNotEmpty) {
          veteranCertJudges.add(r.judge!.toLowerCase());
        }
        veteranCertShows.add('${r.showName}_${r.date.toIso8601String()}'.toLowerCase());
      }
    }
    final int noVetChProgress = [veteranCertCount, veteranCertJudges.length, veteranCertShows.length].reduce((a, b) => a < b ? a : b).clamp(0, 3);

    // ──── NORDIC UCH ────
    // Rules: Must be NO UCH + 3 Nordic Cert from 3 different Nordic countries, 
    // from 3 different judges. At least 1 at 24 months or later.
    int nordiskCertCount = 0;
    final nordiskCertJudges = <String>{};

    for (final r in results) {
      if (hasCertType(r, 'Nordisk Cert')) {
        nordiskCertCount++;
        if (r.judge != null && r.judge!.isNotEmpty) {
          nordiskCertJudges.add(r.judge!.toLowerCase());
        }
      }
    }
    final int nordUchProgress = [nordiskCertCount, nordiskCertJudges.length].reduce((a, b) => a < b ? a : b).clamp(0, 3);

    // ──── NORDIC JrCH ────
    // Rules: 3 Nordic Junior Cert from 2 different Nordic countries, from 3 different judges
    int nordiskJuniorCertCount = 0;
    final nordiskJuniorJudges = <String>{};

    for (final r in results) {
      if (hasCertType(r, 'Nordisk Junior Cert')) {
        nordiskJuniorCertCount++;
        if (r.judge != null && r.judge!.isNotEmpty) {
          nordiskJuniorJudges.add(r.judge!.toLowerCase());
        }
      }
    }
    final int nordJrChProgress = [nordiskJuniorCertCount, nordiskJuniorJudges.length].reduce((a, b) => a < b ? a : b).clamp(0, 3);

    // ──── NORDIC VetCH ────
    // Rules: 3 Nordic Veteran Cert from 2 different Nordic countries, from 3 different judges
    int nordiskVeteranCertCount = 0;
    final nordiskVeteranJudges = <String>{};

    for (final r in results) {
      if (hasCertType(r, 'Nordisk Veteran Cert')) {
        nordiskVeteranCertCount++;
        if (r.judge != null && r.judge!.isNotEmpty) {
          nordiskVeteranJudges.add(r.judge!.toLowerCase());
        }
      }
    }
    final int nordVetChProgress = [nordiskVeteranCertCount, nordiskVeteranJudges.length].reduce((a, b) => a < b ? a : b).clamp(0, 3);

    // ──── C.I.B (Internasjonal Utstillingschampionat) ────
    // Default (most breeds): 4 CACIB in 3+ countries from 3+ judges.
    // 12 months + 1 day between first and last CACIB.
    // Breeds with work req: 2 CACIB in 2 countries + work test.
    // We track the general case (4 CACIB) since we don't know breed group here.
    int cacibCount = 0;
    final cacibJudges = <String>{};
    DateTime? firstCacibDate;
    DateTime? lastCacibDate;

    for (final r in results) {
      if (hasCertType(r, 'Cacib')) {
        cacibCount++;
        if (r.judge != null && r.judge!.isNotEmpty) {
          cacibJudges.add(r.judge!.toLowerCase());
        }
        if (firstCacibDate == null || r.date.isBefore(firstCacibDate)) {
          firstCacibDate = r.date;
        }
        if (lastCacibDate == null || r.date.isAfter(lastCacibDate)) {
          lastCacibDate = r.date;
        }
      }
    }
    bool cacibTimeMet = true;
    if (firstCacibDate != null && lastCacibDate != null && cacibCount >= 2) {
      // Must be at least 366 days between first and last
      cacibTimeMet = lastCacibDate.difference(firstCacibDate).inDays >= 366;
    } else if (cacibCount < 2) {
      cacibTimeMet = false;
    }

    // ──── C.I.B-J (Internasjonal Juniorchampionat) ────
    int juniorCacibCount = 0;
    final juniorCacibJudges = <String>{};
    for (final r in results) {
      if (hasCertType(r, 'Junior Cacib')) {
        juniorCacibCount++;
        if (r.judge != null && r.judge!.isNotEmpty) {
          juniorCacibJudges.add(r.judge!.toLowerCase());
        }
      }
    }

    // ──── C.I.B-V (Internasjonal Veteranchampionat) ────
    int veteranCacibCount = 0;
    final veteranCacibJudges = <String>{};
    for (final r in results) {
      if (hasCertType(r, 'Veteran Cacib')) {
        veteranCacibCount++;
        if (r.judge != null && r.judge!.isNotEmpty) {
          veteranCacibJudges.add(r.judge!.toLowerCase());
        }
      }
    }

    // ──── CK / BIR / BIM counting (informational) ────
    final ckDates = <DateTime>{};
    int birCount = 0;
    int bimCount = 0;
    int resCertCount = 0;
    int resCacibCount = 0;

    for (final r in results) {
      if (r.gotCK) ckDates.add(DateTime(r.date.year, r.date.month, r.date.day));
      if (r.placement == 'BIR') birCount++;
      if (r.placement == 'BIM') bimCount++;
      if (hasCertType(r, 'Res.Cert')) resCertCount++;
      if (hasCertType(r, 'Res.Cacib')) resCacibCount++;
    }

    // ──── Build title progress list ────
    final titles = <TitleProgress>[];
    final tilleggskrav = dogBreed != null ? getTilleggskrav(dogBreed) : null;
    final fciGroup = dogBreed != null ? getFciGroup(dogBreed) : null;

    // NO UCH
    final noUchNotes = <String>[];
    if (certCount > 0 && !hasCertAfter24Months && dogDateOfBirth != null) {
      noUchNotes.add('Mangler cert etter fylte 24 mnd');
    }
    if (certJudges.length < 3 && certCount >= 3) {
      noUchNotes.add('Trenger ${3 - certJudges.length} flere unike dommere');
    }
    if (tilleggskrav != null && !tilleggskravCompleted) {
      noUchNotes.add('Tilleggskrav ikke oppfylt (${tilleggskrav.kravType})');
    }

    String noUchDesc = '3 Cert fra 3 forskjellige dommere. Min. 1 cert etter fylte 24 mnd.';
    if (tilleggskrav != null) {
      noUchDesc += '\n+ Tilleggskrav (${tilleggskrav.kravType}) for ${dogBreed ?? 'rasen'}.';
    }

    titles.add(TitleProgress(
      titleName: 'NO UCH',
      fullName: 'Norsk Utstillingschampion',
      current: noUchProgress,
      required: 3,
      description: noUchDesc,
      notes: noUchNotes.isNotEmpty ? noUchNotes : null,
      tilleggskrav: tilleggskrav,
      tilleggskravCompleted: tilleggskravCompleted,
      detailCounts: {
        'Cert': certCount,
        'Unike dommere': certJudges.length,
        'Cert etter 24 mnd': hasCertAfter24Months ? 1 : 0,
        if (fciGroup != null) 'FCI-gruppe': fciGroup,
      },
    ));

    // NO JrCH
    if (juniorCertCount > 0 || results.any((r) => r.showClass == 'Junior')) {
      titles.add(TitleProgress(
        titleName: 'NO JrCH',
        fullName: 'Norsk Juniorchampion',
        current: noJrChProgress,
        required: 3,
        description: '3 Junior Cert fra 3 forskjellige dommere på 3 NKK-utstillinger.',
        detailCounts: {
          'Junior Cert': juniorCertCount,
          'Unike dommere': juniorCertJudges.length,
          'Ulike utstillinger': juniorCertShows.length,
        },
      ));
    }

    // NO VetCH
    if (veteranCertCount > 0 || results.any((r) => r.showClass == 'Veteran')) {
      titles.add(TitleProgress(
        titleName: 'NO VetCH',
        fullName: 'Norsk Veteranchampion',
        current: noVetChProgress,
        required: 3,
        description: '3 Veteran Cert fra 3 forskjellige dommere på 3 NKK-utstillinger.',
        detailCounts: {
          'Veteran Cert': veteranCertCount,
          'Unike dommere': veteranCertJudges.length,
          'Ulike utstillinger': veteranCertShows.length,
        },
      ));
    }

    // NORDIC UCH
    if (nordiskCertCount > 0 || noUchProgress >= 3) {
      final nordNotes = <String>[];
      if (noUchProgress < 3) {
        nordNotes.add('Krever NO UCH først');
      }
      titles.add(TitleProgress(
        titleName: 'NORDIC UCH',
        fullName: 'Nordisk Utstillingschampion',
        current: nordUchProgress,
        required: 3,
        description: 'NO UCH + 3 Nordisk Cert fra 3 ulike nordiske land, 3 forskjellige dommere.',
        notes: nordNotes.isNotEmpty ? nordNotes : null,
        prerequisite: noUchProgress < 3 ? 'Krever NO UCH' : null,
        detailCounts: {
          'Nordisk Cert': nordiskCertCount,
          'Unike dommere': nordiskCertJudges.length,
        },
      ));
    }

    // NORDIC JrCH
    if (nordiskJuniorCertCount > 0) {
      titles.add(TitleProgress(
        titleName: 'NORDIC JrCH',
        fullName: 'Nordisk Juniorchampion',
        current: nordJrChProgress,
        required: 3,
        description: '3 Nordisk Junior Cert fra 2 ulike nordiske land, 3 forskjellige dommere.',
        detailCounts: {
          'Nordisk Junior Cert': nordiskJuniorCertCount,
          'Unike dommere': nordiskJuniorJudges.length,
        },
      ));
    }

    // NORDIC VetCH
    if (nordiskVeteranCertCount > 0) {
      titles.add(TitleProgress(
        titleName: 'NORDIC VetCH',
        fullName: 'Nordisk Veteranchampion',
        current: nordVetChProgress,
        required: 3,
        description: '3 Nordisk Veteran Cert fra 2 ulike nordiske land, 3 forskjellige dommere.',
        detailCounts: {
          'Nordisk Veteran Cert': nordiskVeteranCertCount,
          'Unike dommere': nordiskVeteranJudges.length,
        },
      ));
    }

    // C.I.B
    if (cacibCount > 0) {
      // Breeds with tilleggskrav (groups 1,2,3,4,5,6,7,8 partly) only need 2 CACIB
      final bool hasBrukskrav = tilleggskrav != null;
      final int requiredCacib = hasBrukskrav ? 2 : 4;
      final int requiredCountries = hasBrukskrav ? 2 : 3;
      final int requiredJudges = hasBrukskrav ? 2 : 3;

      final cibNotes = <String>[];
      if (cacibCount >= 2 && !cacibTimeMet) {
        cibNotes.add('Min. 1 år og 1 dag mellom første og siste CACIB');
      }
      if (cacibJudges.length < requiredJudges && cacibCount >= requiredCacib) {
        cibNotes.add('Trenger ${requiredJudges - cacibJudges.length} flere unike dommere');
      }
      if (hasBrukskrav) {
        cibNotes.add('Krav: $requiredCacib CACIB i $requiredCountries land + ${tilleggskrav.kravType}');
      }
      titles.add(TitleProgress(
        titleName: 'C.I.B',
        fullName: 'Internasjonal Utstillingschampion',
        current: cacibCount.clamp(0, requiredCacib),
        required: requiredCacib,
        description: hasBrukskrav
            ? '$requiredCacib CACIB i $requiredCountries ulike land, $requiredJudges dommere + brukskrav. Min. 1 år mellom.'
            : '4 CACIB i min. 3 ulike land, 3 forskjellige dommere. Min. 1 år mellom.',
        notes: cibNotes.isNotEmpty ? cibNotes : null,
        detailCounts: {
          'CACIB': cacibCount,
          'Unike dommere': cacibJudges.length,
          'Tidskrav oppfylt': cacibTimeMet ? 1 : 0,
        },
      ));
    }

    // C.I.B-J
    if (juniorCacibCount > 0) {
      titles.add(TitleProgress(
        titleName: 'C.I.B-J',
        fullName: 'Internasjonal Juniorchampion',
        current: juniorCacibCount.clamp(0, 3),
        required: 3,
        description: '3 CACIB-J i 3 ulike land, 3 forskjellige dommere.',
        detailCounts: {
          'Junior CACIB': juniorCacibCount,
          'Unike dommere': juniorCacibJudges.length,
        },
      ));
    }

    // C.I.B-V
    if (veteranCacibCount > 0) {
      titles.add(TitleProgress(
        titleName: 'C.I.B-V',
        fullName: 'Internasjonal Veteranchampion',
        current: veteranCacibCount.clamp(0, 3),
        required: 3,
        description: '3 CACIB-V i 3 ulike land, 3 forskjellige dommere.',
        detailCounts: {
          'Veteran CACIB': veteranCacibCount,
          'Unike dommere': veteranCacibJudges.length,
        },
      ));
    }

    // ──── Informational stats ────
    titles.add(TitleProgress(
      titleName: 'CK',
      fullName: 'Certifikat Kvalitet',
      current: ckDates.length,
      required: 0,
      description: 'Totalt antall CK',
      isInformational: true,
    ));

    titles.add(TitleProgress(
      titleName: 'BIR',
      fullName: 'Best I Rasen',
      current: birCount,
      required: 0,
      description: 'Totalt antall BIR',
      isInformational: true,
    ));

    titles.add(TitleProgress(
      titleName: 'BIM',
      fullName: 'Best I Motsatt kjønn',
      current: bimCount,
      required: 0,
      description: 'Totalt antall BIM',
      isInformational: true,
    ));

    if (resCertCount > 0) {
      titles.add(TitleProgress(
        titleName: 'Res.Cert',
        fullName: 'Reserve Certifikat',
        current: resCertCount,
        required: 0,
        description: 'Totalt antall Res.Cert',
        isInformational: true,
      ));
    }

    if (resCacibCount > 0) {
      titles.add(TitleProgress(
        titleName: 'Res.CACIB',
        fullName: 'Reserve CACIB',
        current: resCacibCount,
        required: 0,
        description: 'Kan omgjøres til CACIB under spesielle vilkår (se NKK regler)',
        isInformational: true,
      ));
    }

    return TitleProgression(
      titles: titles,
      totalCert: certCount,
      totalCacib: cacibCount,
      totalNordiskCert: nordiskCertCount,
      totalBIR: birCount,
      totalCK: ckDates.length,
    );
  }
}

/// Title progress for a specific championship
class TitleProgress {
  final String titleName;
  final String fullName;
  final int current;
  final int required;
  final String description;
  final bool isInformational;
  final List<String>? notes;        // Extra info/warnings
  final String? prerequisite;        // Required title before this can be achieved
  final Map<String, int>? detailCounts; // Detailed breakdown
  final NkkTilleggskrav? tilleggskrav; // Breed-specific additional requirements
  final bool tilleggskravCompleted;    // Whether tilleggskrav is fulfilled

  TitleProgress({
    required this.titleName,
    required this.fullName,
    required this.current,
    required this.required,
    required this.description,
    this.isInformational = false,
    this.notes,
    this.prerequisite,
    this.detailCounts,
    this.tilleggskrav,
    this.tilleggskravCompleted = false,
  });

  double get progress => required > 0 ? (current / required).clamp(0.0, 1.0) : 0.0;
  bool get isComplete {
    if (required <= 0 || current < required) return false;
    if (prerequisite != null) return false;
    // If there's a tilleggskrav and it's not completed, title is not complete
    if (tilleggskrav != null && !tilleggskravCompleted) return false;
    return true;
  }
  int get remaining => required > 0 ? (required - current).clamp(0, required) : 0;
}

/// Overall title progression for a dog
class TitleProgression {
  final List<TitleProgress> titles;
  final int totalCert;
  final int totalCacib;
  final int totalNordiskCert;
  final int totalBIR;
  final int totalCK;

  TitleProgression({
    required this.titles,
    required this.totalCert,
    required this.totalCacib,
    required this.totalNordiskCert,
    required this.totalBIR,
    required this.totalCK,
  });
}

/// Breed-specific additional requirements for NO UCH
class NkkTilleggskrav {
  final int fciGroup;
  final String breedName;
  final String description;
  final String kravType; // e.g. 'Bruksprøve', 'Jaktprøve', 'Drevprøve'

  NkkTilleggskrav({
    required this.fciGroup,
    required this.breedName,
    required this.description,
    required this.kravType,
  });
}

/// A fuzzy match result when searching for similar names
class SimilarNameMatch {
  final String name;
  final double similarity;
  final bool isExactNormalized; // true if names match after normalization

  SimilarNameMatch({
    required this.name,
    required this.similarity,
    required this.isExactNormalized,
  });
}
