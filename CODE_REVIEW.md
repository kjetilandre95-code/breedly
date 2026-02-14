# Breedly - Kodekvalitet og Optimiserings Rapport

## Sammendrag
**Status:** Appen har 93 advarsler, 0 kritiske feil
**Hovedproblemer:**
1. Bruk av utdaterte Flutter API-er (deprecated)
2. `print()` statements i produksjonskode
3. Duplikat UI-mønster i formularer
4. Unødvendige `.toList()` i spreads

---

## 1. KRITISKE PROBLEMER (LØST ✅)

### ✅ Unused variables og imports
- **Filtre:** `home_screen.dart` (line 147), `temperature_tracking_screen.dart` (line 79, 7)
- **Status:** LØST
- **Handling:** Fjernet `final localizations = AppLocalizations.of(context)!;` der variabelen ikke ble brukt
- **Handling:** Fjernet `import 'package:fl_chart/fl_chart.dart';` som ikke ble brukt
- **Handling:** Fjernet `import 'package:breedly/generated_l10n/app_localizations.dart';` fra temperature_tracking_screen

### ✅ Widget Test feil
- **Fil:** `test/widget_test.dart` (line 16)
- **Problem:** MyApp() krever `languageProvider` parameter
- **Status:** LØST
- **Handling:** Lagt til `import 'package:breedly/providers/language_provider.dart';` og pass `LanguageProvider()` til MyApp

---

## 2. HØYPRIORITET - DEPRECATED API BRUK

### A. `.withOpacity()` → `.withValues()` 
**Antall:** 20+ forekomster
**Filer som påvirkes:**
- `buyers_screen.dart` (2 forekomster)
- `dog_detail_screen.dart` (6 forekomster)
- `dogs_screen.dart` (2 forekomster)
- `finance_screen.dart` (4 forekomster)
- `gallery_screen.dart` (2 forekomster)
- `home_screen.dart` (5 forekomster)
- `litter_detail_screen.dart` (11 forekomster)
- `settings_screen.dart` (1 forekomst)
- `temperature_tracking_screen.dart` (2 forekomster)
- `ui_helpers.dart` (2 forekomster)

**Oppgradering:**
```dart
// Før (deprecated)
Colors.grey[400].withOpacity(0.08)

// Etter (ny måte)
Colors.grey[400]!.withValues(alpha: 0.08)
```

**Estimert innsats:** 5 minutter (kan gjøres med find-replace)

### B. DropdownButtonFormField `value` → `initialValue`
**Antall:** 4 forekomster
**Filer:**
- `add_dog_screen.dart` (line 384)
- `buyers_screen.dart` (lines 348, 387, 582, 621)
- `finance_screen.dart` (lines 558, 659)

**Oppgradering:**
```dart
// Før
DropdownButtonFormField<String>(
  value: selectedValue,
  ...
)

// Etter
DropdownButtonFormField<String>(
  initialValue: selectedValue,
  ...
)
```

### C. Radio Button `value`/`groupValue`/`onChanged` 
**Antall:** 3 forekomster
**Fil:** `settings_screen.dart` (lines 69, 81, 82)

**Oppgradering:**
```dart
// Før (deprecated)
Radio<String>(
  value: 'no',
  groupValue: _selectedLanguage,
  onChanged: (value) { ... },
)

// Etter (bruk RadioGroup)
RadioGroup<String>(
  value: _selectedLanguage,
  onChanged: (value) { ... },
  children: [
    RadioGroupItem(value: 'no', child: Text('Norsk')),
    RadioGroupItem(value: 'sv', child: Text('Svenska')),
  ],
)
```

---

## 3. KODEDUPLICERING - MULIGHET FOR REFACTORING

### A. Formularer for Adding/Editing Entiteter
**Mønster:** Repetitiv Dialog med TextEditingControllers og Submit-logikk

**Påvirkede filer:**
- `buyers_screen.dart` - `_addBuyer()` og `_editBuyer()` (150 linjer hver)
- `finance_screen.dart` - `_addExpense()`, `_addIncome()` (80-100 linjer hver)
- `litter_detail_screen.dart` - `_editPuppy()`, `_editWeightLog()` (100+ linjer hver)
- `add_dog_screen.dart` - `_buildBreedSelectionDialog()` (40+ linjer)

**Potensial for forbedring:**
Lag en reusable `FormDialog` widget eller hjelperfunksjon som håndterer:
- TextEditingController opprettelse og dispose
- Dialog opening/closing
- Validation og error handling
- Submit-logikk

**Estimert reduks:** 200-300 linjer kode

### B. SnackBar Messages
**Forekomster:** 20+
**Pattern:**
```dart
ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(content: Text('Kjøper lagt til')),
);
```

**Forslag:** Lag en hjelperfunksjon:
```dart
// I lib/utils/ui_helpers.dart
static void showSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}
```

---

## 4. DEBUGGING CODE (PRODUKSJON - FJERN)

### Print Statements i Logging
**Antall:** 33 forekomster
**Filer:**
- `notification_service.dart` (12 forekomster)
- `pedigree_parser.dart` (10 forekomster)
- `pdf_generator.dart` (1 forekomst)

**Handling:**
Bytt alle `print()` til en logger:
```dart
// Installér: flutter pub add logger
import 'package:logger/logger.dart';

final logger = Logger();

// Erstatt
print('Debug message');
// Med
logger.d('Debug message');
```

**Eller kutt hvis unødvendig for debugging.**

---

## 5. MINDRE PROBLEMER

### A. Unødvendig `.toList()` i Spreads
**Antall:** 5 forekomster
**Filer:**
- `add_dog_screen.dart` (line 395)
- `buyers_screen.dart` (lines 366, 405, 600, 639)
- `finance_screen.dart` (lines 570, 671)
- `temperature_tracking_screen.dart` (line 467)

**Oppgradering:**
```dart
// Før (unødvendig)
[
  const DropdownMenuItem(value: null, child: Text('Ingen')),
  ...litters.map((l) => DropdownMenuItem(...)).toList(),
]

// Etter
[
  const DropdownMenuItem(value: null, child: Text('Ingen')),
  ...litters.map((l) => DropdownMenuItem(...)),
]
```

### B. `_heatCycles` kan være `final`
**Fil:** `add_dog_screen.dart` (line 25)
```dart
// Før
late List<DateTime> _heatCycles;

// Etter (hvis ikke re-assigned)
late final List<DateTime> _heatCycles;
```

### C. `BuildContext` across async gaps
**Antall:** 6 forekomster (advarsel, ikke feil)
**Filer:**
- `buyers_screen.dart` (line 187)
- `dog_detail_screen.dart` (lines 361, 383, 387)
- `litter_detail_screen.dart` (line 50)
- `temperature_tracking_screen.dart` (line 281)

**Oppgradering:**
```dart
// Før
final result = await showDialog(...);
ScaffoldMessenger.of(context).showSnackBar(...); // Advarsel

// Etter
final result = await showDialog(...);
if (context.mounted) {
  ScaffoldMessenger.of(context).showSnackBar(...);
}
```

### D. Unødvendig string interpolation
**Fil:** `pdf_generator.dart` (line 165)
```dart
// Før
'$value'  // Unødvendig interpolation

// Etter
value.toString()
```

---

## PRIORITERT AKSJONSLISTE

### Prioritet 1 (5 minutter):
- [ ] Replace `.withOpacity()` med `.withValues()` overalt (20+ replace)
- [ ] Fjern alle `print()` statements eller bytt til logger

### Prioritet 2 (10 minutter):
- [ ] Oppdater deprecated DropdownButtonFormField `value` → `initialValue`
- [ ] Fikk `BuildContext` across async gaps med `.mounted` checks
- [ ] Fjern unødvendig `.toList()` i spreads

### Prioritet 3 (30+ minutter - Refactoring):
- [ ] Lag reusable FormDialog widget for add/edit dialogs
- [ ] Lag SnackBar hjelperfunksjon i UIHelpers
- [ ] Konsolider RadioButton i settings_screen

### Prioritet 4 (Valgfritt):
- [ ] Legg til Logger package for debugging
- [ ] Legg til linter rules i analysis_options.yaml for å unngå deprecated bruk

---

## KODEMODULERING - POSITIVE FUNN

✅ **Bra praktikker funnet:**
- Konsistent bruk av Hive for databaselagring
- God lokalisering (i18n) implementering
- Gode hjelperfunksjoner i `UIHelpers` og `ui_constants.dart`
- Modulær skjermstruktur
- Reusable modeller med `.g.dart` generatorer

---

## KOMMANDOER FOR AUTOMATISK FIXING

```bash
# 1. Generer kode på nytt
dart pub run build_runner build --delete-conflicting-outputs

# 2. Kjør analyzefor å se alle advarsler
flutter analyze

# 3. Prøv automatisk fixing (hvis tilgjengelig)
dart fix --apply
```

---

## KONKLUSJON

**Appen er funksjonell** ✅
- Alle kritiske feil løst
- 0 compilation errors
- 93 advarsler (hovedsakelig deprecated API-bruk)

**Anbefalinger:**
1. Oppgrader alle deprecated API-kall (1-2 timer)
2. Fjern/consolidate debugging code (30 minutter)
3. Refaktorer duplicate form logic (2+ timer)
4. Legg til `.mounted` checks for async context bruk (30 minutter)

**Estimert oppgradering:** 3-4 timer for optimal kodekvalitet
