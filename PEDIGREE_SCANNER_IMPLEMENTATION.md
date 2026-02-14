# Stamtavle-skanner - Implementasjonsguide

## 📋 Oversikt

Dette dokumentet beskriver hvordan du kan implementere automatisk skanning og parsing av stamtavler ved hjelp av AI/ML teknologi.

## 🎯 Funksjonalitet

Appen vil kunne:
- ✅ Ta bilde av fysiske stamtavler
- ✅ Laste opp bilder fra galleri
- ✅ Ekstrahere tekst med OCR (Optical Character Recognition)
- ✅ Parse og strukturere data intelligent
- ✅ Identifisere navn, registreringsnummer, relasjoner
- ✅ Opprette flere hunder automatisk med riktig slektskap

## 🔧 Implementasjonsalternativer

### Alternativ 1: Google ML Kit (ANBEFALT FOR START)

#### Fordeler
- ✅ Helt gratis
- ✅ Fungerer offline (on-device)
- ✅ God støtte for norsk tekst
- ✅ Enkel implementasjon
- ✅ Ingen API-nøkler nødvendig

#### Installasjon

1. Legg til pakke i `pubspec.yaml`:
```yaml
dependencies:
  google_mlkit_text_recognition: ^0.13.0
```

2. Kjør:
```bash
flutter pub get
```

3. iOS konfigurasjon - Legg til i `ios/Podfile`:
```ruby
platform :ios, '12.0'  # Øk minimum iOS versjon
```

4. Android - ingen ekstra konfigurasjon nødvendig!

#### Kodeeksempel

```dart
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

Future<PedigreeScanResult> _processWithMLKit(File imageFile) async {
  final inputImage = InputImage.fromFile(imageFile);
  final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  
  final RecognizedText recognizedText = 
      await textRecognizer.processImage(inputImage);
  
  await textRecognizer.close();
  
  // Parse teksten
  return _parseExtractedText(recognizedText.text);
}
```

#### Estimert arbeid
- 4-6 timer for grunnleggende implementasjon
- 8-12 timer med intelligent parsing

---

### Alternativ 2: OpenAI Vision API (BEST KVALITET)

#### Fordeler
- ✅ Ekstremt kraftig og intelligent
- ✅ Forstår struktur og relasjoner
- ✅ Håndterer dårlig kvalitet og håndskrift
- ✅ Kan returnere strukturert JSON direkte
- ✅ Støtter flere språk perfekt

#### Ulemper
- ❌ Koster penger (~$0.01-0.03 per skanning)
- ❌ Krever internettforbindelse
- ❌ Krever API-nøkkel

#### Installasjon

1. Legg til HTTP pakke i `pubspec.yaml`:
```yaml
dependencies:
  http: ^1.1.0
```

2. Få API-nøkkel fra [OpenAI Platform](https://platform.openai.com/api-keys)

3. Legg til i `.env`:
```
OPENAI_API_KEY=sk-your-api-key-here
```

#### Kodeeksempel

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<PedigreeScanResult> _processWithOpenAI(File imageFile) async {
  // Konverter bilde til base64
  final bytes = await imageFile.readAsBytes();
  final base64Image = base64Encode(bytes);
  
  // API kall
  final response = await http.post(
    Uri.parse('https://api.openai.com/v1/chat/completions'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${dotenv.env['OPENAI_API_KEY']}',
    },
    body: jsonEncode({
      'model': 'gpt-4o',  // eller 'gpt-4-turbo' 
      'messages': [
        {
          'role': 'user',
          'content': [
            {
              'type': 'text',
              'text': '''
Extract all information from this dog pedigree document.
Return ONLY valid JSON (no markdown, no explanation) with this exact structure:
{
  "dog": {
    "name": "full name",
    "registrationNumber": "reg number if found",
    "breed": "breed name",
    "birthDate": "DD.MM.YYYY if found",
    "gender": "Male or Female",
    "color": "color if mentioned"
  },
  "father": {
    "name": "father name",
    "registrationNumber": "reg number if found"
  },
  "mother": {
    "name": "mother name", 
    "registrationNumber": "reg number if found"
  },
  "grandparents": {
    "paternalGrandfather": {"name": "", "registrationNumber": ""},
    "paternalGrandmother": {"name": "", "registrationNumber": ""},
    "maternalGrandfather": {"name": "", "registrationNumber": ""},
    "maternalGrandmother": {"name": "", "registrationNumber": ""}
  }
}

If you cannot find certain information, use null for that field.
'''
            },
            {
              'type': 'image_url',
              'image_url': {
                'url': 'data:image/jpeg;base64,$base64Image',
                'detail': 'high'
              }
            }
          ]
        }
      ],
      'max_tokens': 1000,
      'temperature': 0.1,  // Lav temperatur for konsistens
    }),
  );
  
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    final content = data['choices'][0]['message']['content'];
    
    // Parse JSON response
    final pedigreeData = jsonDecode(content);
    return _convertToPedigreeScanResult(pedigreeData);
  } else {
    throw Exception('OpenAI API error: ${response.statusCode}');
  }
}
```

#### Kostnadsberegning
- **gpt-4o**: ~$0.01 per bilde (anbefalt)
- **gpt-4-turbo**: ~$0.03 per bilde
- Hvis 100 stamtavler skannes per måned = $1-3/måned

#### Estimert arbeid
- 3-4 timer implementasjon
- 1-2 timer testing og forbedring

---

### Alternativ 3: Google Cloud Vision API (MELLOMTING)

#### Fordeler
- ✅ Kraftig OCR
- ✅ Bedre enn ML Kit
- ✅ Rimeligere enn OpenAI

#### Ulemper
- ❌ Koster penger (~$1.50 per 1000 bilder)
- ❌ Mer kompleks parsing enn OpenAI
- ❌ Krever Google Cloud prosjekt

#### Installasjon

1. Opprett prosjekt på [Google Cloud Console](https://console.cloud.google.com)
2. Aktiver Cloud Vision API
3. Opprett API-nøkkel
4. Legg til i `.env`

---

## 🛠️ Intelligent Tekstparsing

Uavhengig av OCR-metode må teksten parses intelligent:

```dart
PedigreeScanResult _parseExtractedText(String text) {
  // Regex mønstre for norske stamtavler
  final regPatterns = [
    RegExp(r'N\s?(\d{5})/(\d{2,4})'),  // N 12345/18
    RegExp(r'NO\s?(\d{5})/(\d{2,4})'), // NO 12345/2018
    RegExp(r'[A-Z]{2}\s?\d{4,6}'),     // DK 12345, SE 123456
  ];
  
  final datePattern = RegExp(r'(\d{1,2})[./](\d{1,2})[./](\d{2,4})');
  
  // Split tekst i linjer
  final lines = text.split('\n');
  
  // Finn hoved-hund (vanligvis øverst)
  String? dogName;
  String? dogRegNumber;
  String? birthDate;
  
  // Finn foreldre (vanligvis markert med Far/Mor eller Sire/Dam)
  String? fatherName;
  String? motherName;
  
  // Smart logikk basert på posisjon og nøkkelord
  for (int i = 0; i < lines.length; i++) {
    final line = lines[i].trim();
    
    // Finn registreringsnummer
    for (final pattern in regPatterns) {
      final match = pattern.firstMatch(line);
      if (match != null) {
        // Logikk for å tildele riktig hund
      }
    }
    
    // Finn foreldre
    if (line.toLowerCase().contains('far') || 
        line.toLowerCase().contains('sire')) {
      fatherName = _extractNameFromLine(lines[i + 1]);
    }
    
    if (line.toLowerCase().contains('mor') ||
        line.toLowerCase().contains('dam')) {
      motherName = _extractNameFromLine(lines[i + 1]);
    }
  }
  
  // Bygg resultat
  return PedigreeScanResult(...);
}

String _extractNameFromLine(String line) {
  // Fjern registreringsnummer og andre ikke-navn elementer
  final cleaned = line
      .replaceAll(RegExp(r'[A-Z]{2}\s?\d{4,6}[/\-]?\d{0,2}'), '')
      .replaceAll(RegExp(r'\d{1,2}[./]\d{1,2}[./]\d{2,4}'), '')
      .trim();
  
  return cleaned;
}
```

---

## 📱 Brukergrensesnitt

### Integrasjon i "Legg til hund"-skjerm

I `add_dog_screen.dart`:

```dart
// Legg til øverst i skjemaet
PedigreeScannerWidget(
  onScanComplete: (result) async {
    // Vis resultat for gjennomgang
    final shouldImport = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PedigreeScanReviewScreen(
          scanResult: result,
        ),
      ),
    );
    
    if (shouldImport == true) {
      // Fyll ut felter automatisk
      setState(() {
        _nameController.text = result.dog?.name ?? '';
        _regNumberController.text = result.dog?.registrationNumber ?? '';
        // ... etc
      });
    }
  },
),
```

---

## 🎯 Anbefalinger

### For rask prototype (1 uke):
**→ Google ML Kit** 
- Gratis, enkel å komme i gang
- God nok for de fleste stamtavler
- Krever mer manuell parsing-logikk

### For beste brukeropplevelse (kommersiell app):
**→ OpenAI Vision API**
- Betydelig bedre nøyaktighet
- Håndterer komplekse formater
- Minimal parsing-logikk nødvendig
- Kostnaden er ubetydelig (~$1-5/måned for typisk bruk)

### For mellomting:
**→ ML Kit + Smart Parsing**
- Start med ML Kit
- Invester tid i parsing-algoritmer
- Upgrade til OpenAI senere hvis nødvendig

---

## 📊 Estimert Utviklingstid

| Alternativ | Setup | Implementasjon | Testing | Total |
|------------|-------|----------------|---------|-------|
| ML Kit | 1t | 6-8t | 3-4t | **10-13t** |
| OpenAI | 1t | 3-4t | 2-3t | **6-8t** |
| Cloud Vision | 2t | 5-6t | 3-4t | **10-12t** |

---

## ✅ Neste steg

### Minimal implementasjon (1-2 dager):
1. ✅ Legg til `google_mlkit_text_recognition` i pubspec.yaml
2. ✅ Implementer `PedigreeScannerService` med ML Kit
3. ✅ Legg til `PedigreeScannerWidget` i add_dog_screen
4. ✅ Grunnleggende parsing med regex

### Full implementasjon (3-5 dager):
1. ✅ Alt fra minimal
2. ✅ `PedigreeScanReviewScreen` med redigering
3. ✅ Intelligent parsing med hierarki
4. ✅ Automatisk opprettelse av foreldre/besteforeldre
5. ✅ Kobling til eksisterende hunder via reg.nr.

### Premium implementasjon (1 uke+):
1. ✅ OpenAI Vision API integrasjon
2. ✅ A/B test mot ML Kit
3. ✅ Batch-import av flere stamtavler
4. ✅ PDF-støtte (flere sider)
5. ✅ Maskinlæring for forbedring over tid

---

## 💡 Tips og triks

1. **Bildekvalitet**: La brukeren ta flere bilder hvis første forsøk har lav nøyaktighet
2. **Validering**: Vis alltid resultatet før lagring
3. **Duplikater**: Sjekk registreringsnummer før opprettelse
4. **Feedback**: La brukeren rapportere feil for å forbedre systemet
5. **Cache**: Lagre OCR-resultat for å unngå gjen-beregning

---

## 🔒 Sikkerhet og personvern

- Bilder skal IKKE lagres permanent (kun midlertidig under prosessering)
- OpenAI API: Opt-out av API data training (sett i policy)
- GDPR: Informer bruker om behandling
- Offline-first: Foretrekk ML Kit for personvern

---

## 📞 Support og ressurser

- **ML Kit dokumentasjon**: https://developers.google.com/ml-kit/vision/text-recognition
- **OpenAI Vision guide**: https://platform.openai.com/docs/guides/vision
- **Flutter image_picker**: https://pub.dev/packages/image_picker

---

**Konklusjon**: Dette er en svært gjennomførbar funksjon som vil spare brukere for mye tid. Start med ML Kit for rask prototype, vurder OpenAI for produksjon hvis budsjettet tillater det.
