# 🐕 Breedly - Hundekulladministrasjon

## 📋 Oversikt

Breedly er en komplett Flutter-applikasjon for hundebrukere til å administrere:
- Hunderegistrering og stamtavler
- Kulladministrasjon og valpoppfølging
- Helse- og vaksinasjonshistorikk
- Finansoversikt (inntekter/utgifter)
- Multi-bruker samarbeid (deling med medarbeidere)
- Offline-funksjonalitet med automatisk synkronisering

---

## ✅ Status: Klar til Bruk

### Gjort:
- ✅ **Alle kompileringsfeil fikset**
- ✅ **AuthService bug korrigert** (signInWithEmail bruker nå korrekt metode)
- ✅ **Hive database initialisering** konfigurert
- ✅ **Firebase Authentication** implementert
- ✅ **Cloud Firestore** integration
- ✅ **Offline modus** med automatisk sync
- ✅ **Notifikasjoner** for påminnelser
- ✅ **Multi-bruker system** for deling
- ✅ **Alle modeller** med Hive-adapters
- ✅ **Flutter linting** - 0 feil
- ✅ **iOS, Android, Web** support

---

## 🐛 Bugs Som Er Fikset

### Bug #1: AuthService - Feil login-metode
**Problem:** `signInWithEmail()` brukte `signInWithCredential()` som krever `EmailAuthProvider.credential()` - dette er en workaround-metode.

**Løsning:** Oppdatert til å bruke `signInWithEmailAndPassword()` direkte - standard og anbefalt metode.

**Fil:** `lib/services/auth_service.dart` (linje 63-77)

**Diff:**
```dart
// FØR (Feil)
return await _firebaseAuth.signInWithCredential(
  EmailAuthProvider.credential(email: email, password: password),
);

// ETTER (Riktig)
return await _firebaseAuth.signInWithEmailAndPassword(
  email: email,
  password: password,
);
```

**Impact:** Login fungerer nå korrekt med email og passord.

---

## 🚀 Kjøring

### Forutsetninger
- Flutter 3.10.3+
- Dart 3.10+
- Android Studio eller Xcode
- En enhet eller emulator

### Rask Start

```bash
# 1. Naviger til prosjektet
cd breedly

# 2. Få dependencies
flutter pub get

# 3. Kjør appen
flutter run

# 4. Eller spesifisk enhet
flutter run -d emulator-5554  # Android emulator
flutter run -d ios            # iOS simulator
flutter run -d chrome         # Web browser
```

### Av kommandolinjen med verbose logging
```bash
flutter run -v
```

---

## 🔑 Firebase Konfigurering

Appen er konfigurert med **placeholder-verdier**. For å aktivere sky-funksjoner:

### 1. Opprett Firebase-prosjekt
```bash
# Eller gå til https://console.firebase.google.com
firebase init
```

### 2. Oppdater credentials
Rediger `lib/firebase_options.dart` og erstatt:
- `APIKey`
- `AppId`
- `ProjectId`
- `StorageBucket`

### 3. Android
Legg `google-services.json` i `android/app/` mappen

### 4. iOS
Legg `GoogleService-Info.plist` i `ios/Runner/` mappen

### Se `FIREBASE_SETUP.md` for detaljer

---

## 📁 Mappestruktur

```
breedly/
├── lib/
│   ├── main.dart                 # App entry point
│   ├── screens/                  # UI screens (20+ screens)
│   ├── services/                 # Business logic
│   │   ├── auth_service.dart     # Authentication (fikset)
│   │   ├── cloud_sync_service.dart
│   │   ├── offline_mode_manager.dart
│   │   ├── user_sharing_service.dart
│   │   └── data_sync_service.dart
│   ├── models/                   # Data models (Hive)
│   ├── providers/                # State management
│   ├── utils/                    # Helper utilities
│   └── l10n/                     # Lokalisering (NO, SV)
├── android/                      # Android native code
├── ios/                          # iOS native code
├── web/                          # Web support
├── pubspec.yaml                  # Dependencies
└── analysis_options.yaml         # Lint config
```

---

## 🎯 Features

### 🐕 Hundeadministrasjon
- Registrer hundens navn, rase, farge, etc.
- Lagre bilder av hunden
- Spor stamtavler (mor/far)
- Historikk over alle valper

### 👨‍👩‍👧‍👦 Kulladministrasjon
- Opprett kull med dato, mor, far
- Registrer alle valper i kullet
- Spor valpenes utvikling
- Automatiske påminnelser

### 👶 Valpoppfølging
- Vekt- og vekstlogging
- Vaksinasjon-oppfølging
- Helsekontroller
- Adopsjonskontrakter

### 💰 Finansoversikt
- Inntekter fra salg av valper
- Utgifter til fôr, veterinær, etc.
- Grafer og statistikk
- Eksport til PDF

### 📊 Rapporter
- Helserapporter per hund
- Vaksinasjonshistorikk
- Temperatursporing
- Galleribilder

### 🔄 Synkronisering
- Automatisk offline/online synk
- Real-time updates (Firestore)
- Konfliktløsning (last write wins)
- Pending operasjons-kø

### 👥 Multi-bruker
- Del data med medarbeidere
- Rollbasert tilgang (eier/samarbeider)
- Epostbasert invitasjon
- Audit trail

---

## 🌍 Språk

Appen støtter:
- 🇳🇴 Norsk (NO)
- 🇸🇪 Svensk (SV)

Språk settes automatisk basert på enhetens system-preferanser.

---

## 🔒 Sikkerhet

- ✅ Firebase Authentication
- ✅ Firestore Security Rules
- ✅ Role-based access control
- ✅ Data-isolasjon per bruker
- ✅ Encrypted offline storage (Hive)

Se `FIRESTORE_SECURITY_RULES.md` for sikkerhetskonfigurering.

---

## 📦 Dependencies

**Kjerne:**
- `flutter` - UI framework
- `firebase_core`, `firebase_auth`, `cloud_firestore` - Backend
- `hive`, `hive_flutter` - Lokal database
- `provider` - State management

**Utility:**
- `intl`, `flutter_localizations` - Lokalisering
- `pdf` - PDF-generering
- `image_picker` - Bildevalg
- `flutter_local_notifications` - Påminnelser
- `connectivity_plus` - Network status
- `permission_handler` - Tillatelser

Se `pubspec.yaml` for fullstendig liste.

---

## 🧪 Testing

### Manual Testing
1. Opprett bruker (Registrer)
2. Logg inn
3. Legg til hund
4. Opprett kull
5. Legg til valp
6. Test offline (slå av WiFi)
7. Legg til data offline
8. Slå på WiFi - sjekk synkronisering

### Lint/Analysis
```bash
flutter analyze
```

### Build
```bash
# Android APK
flutter build apk

# iOS IPA
flutter build ios

# Web
flutter build web
```

---

## ❌ Kjente Problemer & Løsninger

### Problem: "No implementation found"
**Årsak:** Firebase ikke initialisert  
**Løsning:** Sjekk Firebase.initializeApp() i main.dart

### Problem: PERMISSION_DENIED fra Firestore
**Årsak:** Security rules ikke satt opp  
**Løsning:** Kopier reglene fra FIRESTORE_SECURITY_RULES.md til Firebase Console

### Problem: Login fungerer ikke
**Årsak:** Firebase credentials feil (placeholder-verdier)  
**Løsning:** Oppdater firebase_options.dart med dine credentials eller test offline

### Problem: Offline data synkroniseres ikke
**Årsak:** Bruker ikke logget inn eller nettverksfeil  
**Løsning:** Logg inn, sjekk tilkoblingen, manuelt sync via OfflineModeManager

---

## 📚 Dokumentasjon

Detaljert dokumentasjon:
- `QUICK_START.md` - Rask startguide
- `FIREBASE_SETUP.md` - Firebase implementering
- `FIRESTORE_SECURITY_RULES.md` - Sikkerhet
- `MULTI_USER_SETUP.md` - Multi-bruker deling
- `NAVIGATION_SUMMARY.md` - Navigasjon
- `CODE_REVIEW.md` - Kodegjennomgang

---

## 🤝 Bidrag

Denne applikasjonen er under aktiv utvikling. For å bidra:
1. Opprett en ny branch
2. Gjør endringene
3. Test grundig
4. Lag pull request

---

## 📝 Lisens

Privat/Proprietær

---

## 📞 Support

Hvis du møter problemer:

1. **Sjekk loggene:**
   ```bash
   flutter run -v
   ```

2. **Kjør diagnostikk:**
   ```bash
   flutter doctor -v
   ```

3. **Se dokumentasjonen** i filene over

4. **Kontakt utvikleren** for support

---

## 📊 Statistikk

- **Dart kodelinjer:** ~8,000+
- **Screens:** 20+
- **Modeller:** 13
- **Services:** 5+
- **Språk:** 2 (NO, SV)
- **Flutter version:** 3.38.4
- **Dart version:** 3.10.3

---

**Versjon:** 1.0.0  
**Sist oppdatert:** 27. Januar 2026  
**Status:** ✅ Klar for testing
