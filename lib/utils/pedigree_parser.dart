class PedigreeData {
  String? dogName;
  String? dogRegNumber;
  String? breed;
  String? color;
  String? gender;
  
  String? sireName;
  String? sireRegNumber;
  String? sireTitle;
  
  String? damName;
  String? damRegNumber;
  String? damTitle;
  
  // Besteforeldre (Grandparents)
  String? patGrandfather; // far sin far
  String? patGrandmotherTitle;
  String? patGrandmother;
  String? patGrandmotherRegNumber;
  
  String? matGrandfather; // mor sin far
  String? matGrandfatherRegNumber;
  String? matGrandmother; // mor sin mor
  String? matGrandmotherRegNumber;

  @override
  String toString() {
    return '''
Hund: $dogName ($dogRegNumber)
Rase: $breed, Farge: $color, Kjønn: $gender

Far: $sireTitle $sireName ($sireRegNumber)
  Farfar: $patGrandfather
  Farmor: $patGrandmother ($patGrandmotherRegNumber)

Mor: $damTitle $damName ($damRegNumber)
  Morfar: $matGrandfather ($matGrandfatherRegNumber)
  Mormor: $matGrandmother ($matGrandmotherRegNumber)
    ''';
  }
}

class PedigreeParser {
  /// Parse OCR text from Norwegian Kennel Club pedigree
  static PedigreeData? parseNorwegianPedigree(String ocrText) {
    if (ocrText.isEmpty) return null;

    try {
      final data = PedigreeData();
      final lines = ocrText.split('\n').map((e) => e.trim()).toList();

      // Debug: Total lines: ${lines.length}
      
      // Extract main dog info with flexible patterns
      data.dogName = _extractValue(lines, 'Hundenavnet:') ?? 
                     _extractValue(lines, 'Exentri\'s') ??
                     _findFirstDogName(lines);
      data.breed = _extractValue(lines, 'Rasenavn:') ?? _extractValue(lines, 'KeeShOnd');
      data.color = _extractValue(lines, 'Farge og tegninger:') ?? _extractValue(lines, 'Sølv');
      data.gender = _extractValue(lines, 'Kjønn:');
      data.dogRegNumber = _extractValue(lines, 'reg nr:') ?? _extractValue(lines, 'NOS');

      // Debug: Dog Name: ${data.dogName}, Breed: ${data.breed}, Color: ${data.color}

      // Extract sire (far) - look for section header
      int sireIndex = -1;
      for (int i = 0; i < lines.length; i++) {
        if ((lines[i].contains('Far') || lines[i].contains('Fathq')) && 
            !lines[i].contains('Farfar') && !lines[i].contains('Farmor')) {
          sireIndex = i;
          break;
        }
      }

      if (sireIndex != -1) {
        // Find next meaningful line(s) after "Far"
        for (int j = sireIndex + 1; j < lines.length && j < sireIndex + 5; j++) {
          if (lines[j].isNotEmpty) {
            final sireInfo = _parseDogLine(lines[j]);
            if (sireInfo['name'] != null && sireInfo['name']!.isNotEmpty) {
              data.sireName = sireInfo['name'];
              data.sireRegNumber = sireInfo['regNumber'];
              data.sireTitle = sireInfo['title'];
              // Debug: Sire: ${data.sireName} (${data.sireRegNumber})
              break;
            }
          }
        }
      }

      // Extract dam (mor) - look for section header
      int damIndex = -1;
      for (int i = 0; i < lines.length; i++) {
        if ((lines[i].contains('Mor') || lines[i].contains('Mothq')) && 
            !lines[i].contains('Farmor') && !lines[i].contains('Mormor')) {
          damIndex = i;
          break;
        }
      }

      if (damIndex != -1) {
        // Find next meaningful line(s) after "Mor"
        for (int j = damIndex + 1; j < lines.length && j < damIndex + 5; j++) {
          if (lines[j].isNotEmpty && !lines[j].contains('Farmor') && !lines[j].contains('Mormor')) {
            final damInfo = _parseDogLine(lines[j]);
            if (damInfo['name'] != null && damInfo['name']!.isNotEmpty) {
              data.damName = damInfo['name'];
              data.damRegNumber = damInfo['regNumber'];
              data.damTitle = damInfo['title'];
              // Debug: Dam: ${data.damName} (${data.damRegNumber})
              break;
            }
          }
        }
      }

      // Debug: END
      return data;
    } catch (e) {
      // Error parsing pedigree: $e
      return null;
    }
  }

  /// Try to find first dog name in document
  static String? _findFirstDogName(List<String> lines) {
    for (var line in lines) {
      // Look for lines with Exentri or similar patterns
      if (line.contains('Exentri') || line.contains('Could Be')) {
        return line;
      }
    }
    return null;
  }

  /// Extract value after a key
  static String? _extractValue(List<String> lines, String key) {
    for (var line in lines) {
      if (line.contains(key)) {
        final parts = line.split(key);
        if (parts.length > 1) {
          return parts[1].trim().split('\n')[0].trim();
        }
      }
    }
    return null;
  }

  /// Parse a dog line to extract name, title, and registration number
  static Map<String, String?> _parseDogLine(String line) {
    final result = <String, String?>{};
    
    if (line.isEmpty) return result;

    // Try to extract registration number (formats like Fr47295n6, AKCNM79499403, FI59l06/11, NOS5138/23)
    final regNumberPatterns = [
      RegExp(r'\b([A-Z]{2,}\d{6,})\b'), // Fr47295n6 style
      RegExp(r'\b(N[A-Z]{0,1}\d+/\d+)\b'), // NOS5138/23 style
      RegExp(r'\b([A-Z]{2,}[A-Z0-9/\-]{4,})\b'), // Generic
    ];

    String? regNumber;
    for (var pattern in regNumberPatterns) {
      final match = pattern.firstMatch(line);
      if (match != null) {
        regNumber = match.group(1);
        if (regNumber != null && regNumber.length > 3) {
          result['regNumber'] = regNumber;
          break;
        }
      }
    }

    // Extract title - common FCI/national titles
    final titlePatterns = [
      r'C\.I\.B',
      r'NORD',
      r'\bUCH\b',
      r'\bCH\b',
      r'\bJW\b',
      r'DEJV',
      r'DKJV',
      r'DUNX',
      r'\bN\b',
      r'\bSE\b',
      r'\bFI\b',
      r'\bUS\b',
      r'\bUK\b',
      r'FCI',
      r'EEJW',
      r'LVV',
      r'HUV',
      r'NJV',
      r'KDV',
    ];
    
    final titles = <String>[];
    for (var pattern in titlePatterns) {
      final regex = RegExp(pattern);
      for (final match in regex.allMatches(line)) {
        final title = match.group(0);
        if (title != null && title.isNotEmpty && !titles.contains(title)) {
          titles.add(title);
        }
      }
    }
    
    if (titles.isNotEmpty) {
      result['title'] = titles.join(' ');
    }

    // Extract name - remove registration number and titles, keep the middle part
    String name = line;
    
    // Remove registration numbers
    if (regNumber != null) {
      name = name.replaceAll(regNumber, '').trim();
    }
    
    // Remove titles
    for (var title in titles) {
      name = name.replaceAll(RegExp(title), '').trim();
    }
    
    // Remove special characters and extra spaces
    name = name.replaceAll(RegExp(r'[–\-—]'), ' ');
    name = name.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    if (name.isNotEmpty && name.length > 2) {
      result['name'] = name;
    }

    // Debug: Parsed dog from line: "$line"
    // Debug: Name: ${result['name']}, RegNumber: ${result['regNumber']}, Title: ${result['title']}

    return result;
  }
}
