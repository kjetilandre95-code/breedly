# 🧪 Testing av Stamtavle-skanner

## ✅ Implementert

Stamtavle-skanneren er nå implementert med Google ML Kit og kan testes!

## 📱 Hvor finnes funksjonen?

### 1. **I "Legg til hund"-skjermen**
- Åpne appen
- Trykk på "Legg til hund"
- Øverst ser du en blå boks med "Skann stamtavle"
- Trykk "Ta bilde" eller "Velg bilde"

### 2. **Dedikert testskjerm**
For å teste funksjonen separat, legg til denne ruten i navigasjonen:

```dart
// I main.dart eller hvor du håndterer navigasjon
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => PedigreeScannerTestScreen(),
  ),
);
```

## 🚀 Slik tester du

### Forberedelser

1. **Finn en stamtavle**
   - Bruk en ekte fysisk stamtavle
   - Eller finn et bilde av en stamtavle på nettet
   - Eller bruk eksempelbildet nedenfor

2. **Sjekk at kameraet fungerer**
   - iOS: Gi appen kameratilgang i Settings
   - Android: Appen ber om tilgang første gang

### Testprosedyre

#### Test 1: Ta bilde med kamera
```
1. Åpne "Legg til hund"
2. Trykk "Ta bilde" i skannerwidgeten
3. Ta et tydelig bilde av stamtavlen
4. Vent mens ML Kit prosesserer (1-3 sekunder)
5. Se resultatet på "Kontroller skannede data"-skjermen
```

**Forventet resultat:**
- ✅ Hovedhundens navn ekstrahert
- ✅ Registreringsnummer funnet
- ✅ Far og Mor identifisert
- ✅ Nøyaktighet > 70%

#### Test 2: Last opp fra galleri
```
1. Lagre et bilde av en stamtavle i galleriet
2. Åpne "Legg til hund"
3. Trykk "Velg bilde"
4. Velg bildet fra galleriet
5. Se resultatet
```

#### Test 3: Dårlig kvalitet (stress test)
```
1. Ta et uskarpt bilde
2. Eller et bilde med dårlig lys
3. Se hvordan systemet håndterer det
```

**Forventet resultat:**
- ⚠️ Lavere nøyaktighet (< 60%)
- ⚠️ Noen felt mangler
- ✅ Systemet krasjer ikke
- ✅ Feilmelding vises pent

## 📊 Hva systemet kan gjenkjenne

### Registreringsnummer (høy prioritet)
- ✅ `N12345/18`
- ✅ `NO12345/2018`
- ✅ `DK12345`
- ✅ `SE123456`
- ✅ `N12345/18` (uten mellomrom)

### Seksjoner
- ✅ Far / Sire / Father
- ✅ Mor / Dam / Mother
- ✅ Rase / Breed / Race

### Datoer
- ✅ `01.05.2020`
- ✅ `01/05/2020`
- ✅ `01-05-2020`

### Hundenavn
- ✅ Kapitaliserte navn med 2+ ord
- ✅ Kennelnavn inkludert
- ⚠️ Ett-ords navn (kan være utfordrende)

## 🐛 Kjente begrensninger

1. **Håndskrift**: ML Kit er ikke optimalisert for håndskrift
   - Løsning: Bruk OpenAI Vision API for håndskrevne stamtavler

2. **Komplekse layouts**: Hvis stamtavlen har mye grafikk
   - Løsning: Forbedret parsing-logikk

3. **Besteforeldre**: Ikke implementert ennå
   - Status: TODO i koden

4. **Gamle skannede dokumenter**: Lav kvalitet kan gi dårlige resultater
   - Løsning: Forbedre bilde før scanning (contrast, brightness)

## 📸 Eksempel: Test-stamtavle

Du kan lage et enkelt testdokument i Word/PDF med følgende innhold:

```
═══════════════════════════════════════
           STAMTAVLE / PEDIGREE
═══════════════════════════════════════

HOVEDHUND
Name: Breedly's Perfect Storm
Reg.nr: N 12345/2018
Rase: Golden Retriever
Født: 15.06.2018
Kjønn: Hann

───────────────────────────────────────

FAR: Champion Nordic King
Reg.nr: N 11111/2016

MOR: Lovely Lady Luna  
Reg.nr: N 22222/2015

═══════════════════════════════════════
```

**Last ned eller print dette, ta bilde, og test!**

## 📈 Forventet ytelse

| Scenario | Nøyaktighet | Tid |
|----------|-------------|-----|
| Godt bilde, tydelig tekst | 85-95% | 1-2s |
| Middels kvalitet | 70-85% | 2-3s |
| Dårlig kvalitet | 40-70% | 2-4s |
| Håndskrift | 20-40% | 2-3s |

## 🔍 Debug-informasjon

Systemet logger følgende i konsollen (se med `flutter logs`):

```
OCR extracted text: [full text from ML Kit]
Found X registration numbers
Parsed result: X dogs found, confidence: 0.XX
```

### Slik ser du loggene:

```bash
# Terminal 1: Kjør appen
flutter run

# Terminal 2: Se logger
flutter logs
```

## ✨ Neste steg for forbedring

### Kort sikt (1-2 dager)
- [ ] Implementer besteforeldre-parsing
- [ ] Forbedre navnegjenkjenning
- [ ] Batch-import (flere hunder samtidig)

### Mellomlang sikt (1 uke)
- [ ] OpenAI Vision API som alternativ
- [ ] PDF-støtte (multi-page)
- [ ] Bildekvalitet-forbedring (preprocessing)

### Lang sikt (2+ uker)
- [ ] Maskinlæring: Lær av bruker-korreksjoner
- [ ] Automatisk kobling til eksisterende hunder
- [ ] Støtte for forskjellige stamtavle-formater fra ulike land

## 🆘 Feilsøking

### Problem: "ML Kit not configured"
**Løsning:** 
```bash
flutter pub get
flutter clean
flutter pub get
```

### Problem: Kamera åpner ikke
**Løsning iOS:**
- Sjekk `ios/Runner/Info.plist`
- Legg til: `NSCameraUsageDescription`

**Løsning Android:**
- Sjekk `android/app/src/main/AndroidManifest.xml`
- Legg til: `<uses-permission android:name="android.permission.CAMERA" />`

### Problem: OCR finner ingen tekst
**Mulige årsaker:**
1. Bildet er for uskarpt
2. For mørkt eller for lyst
3. Teksten er for liten
4. Bildet er rotert

**Løsning:**
- Ta nytt bilde med bedre forhold
- Bruk flash hvis mørkt
- Hold telefonen stabilt

### Problem: Feil data blir ekstrahert
**Dette er normalt!** Derfor har vi:
- ✅ Redigeringsskjerm før lagring
- ✅ Konfidensscorer for hvert felt
- ✅ Mulighet til manuell korrigering

## 💡 Tips for beste resultat

1. **Belysning**: Jævnt lys uten skygger
2. **Vinkel**: Rett ovenfra (ikke skrått)
3. **Avstand**: Hele stamtavlen skal være i bildet
4. **Stabilitet**: Bruk begge hender
5. **Kontrast**: Mørk tekst på lys bakgrunn fungerer best

## 📞 Support

Hvis du opplever problemer:
1. Sjekk loggene (`flutter logs`)
2. Verifiser at ML Kit er installert korrekt
3. Test med eksempeldokumentet ovenfor
4. Sjekk nettverkstilgang (selv om ML Kit er offline, kan andre features trenge nett)

---

**Ready to test? Ta et bilde av en stamtavle og se magien skje! 🎉**
