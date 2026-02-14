# Breedly - Rask Startguide

## Status
✅ **APPEN ER KLAR TIL TESTING**

### Fulljort:
- ✅ Alle compilingfeil fikset
- ✅ AuthService bug korrigert (`signInWithEmailAndPassword`)
- ✅ Hive-modeller generert
- ✅ Offline sync-system implementert
- ✅ Notifikasjoner konfigurert
- ✅ Multi-bruker sharing-system
- ✅ Flutter linter og analyse ok

---

## Steg 1: Firebase Konfigurering (VIKTIG)

### Alternativ A: Bruke Firebase Console (Anbefalt)
1. Gå til https://console.firebase.google.com
2. Opprett nytt prosjekt: `breedly`
3. **Authentication:**
   - Aktivér: Email/Passord
   - Aktivér: Google Sign-In (trenger OAuth credentials)
4. **Firestore:**
   - Opprett database i `europe-west1`
   - Start i test-modus
5. **Last ned configurationen:**
   - For Android: `google-services.json` → `android/app/`
   - For iOS: `GoogleService-Info.plist` → `ios/Runner/`
6. **Oppdater `firebase_options.dart`:**
   - Kopier credentials fra Firebase Console
   - Erstatt placeholder-verdiene

### Alternativ B: Test-Modus (Rask Test)
Hvis du vil teste uten Firebase:
1. Kommenter ut Firebase initialization i `main.dart`:
   ```dart
   // await Firebase.initializeApp(
   //   options: DefaultFirebaseOptions.currentPlatform,
   // );
   ```
2. Appen bruker lokalt Hive-lager
3. Ingen sky-synk

---

## Steg 2: Kjøre Appen

### Android (Emulator eller Enhet)
```bash
# Fra repo-root
cd breedly
flutter clean
flutter pub get
flutter run -d emulator-5554  # eller device ID
```

### iOS
```bash
flutter run -d ios
```

### Web
```bash
flutter run -d chrome
```

---

## Steg 3: Test Applikasjonen

### Test-bruker (uten Firebase):
- Email: `test@example.com`
- Passord: `password123`

### Hvis Firebase er satt opp:
1. Klikk **Registrer** på login-skjermen
2. Opprett bruker med din email
3. Logg inn
4. Legg til hund
5. Opprett kull
6. Legg til valp
7. Sjekk finansoversikt

---

## Arkitektur & Komponenter

### Services
- **AuthService** - Autentisering (Email + Google)
- **CloudSyncService** - Firestore synkronisering  
- **OfflineModeManager** - Offline/online håndtering
- **UserSharingService** - Multi-bruker deling
- **DataSyncService** - Lokal cache synk

### Storage
- **Hive** - Lokal lagring (alle modeller)
- **Firestore** - Sky-backup (Firebase)
- **Offline queue** - Pending operasjoner

### Features
- 🐕 Hunderegistrering
- 👨‍👩‍👧‍👦 Kulladministrasjon
- 👶 Valpoppfølging
- 💰 Finansoversikt
- 📊 Helserapporter
- 📷 Bildegalleri
- 🔄 Real-time sync
- 👥 Multi-bruker sharing
- 📴 Offline fungering

---

## Feilsøking

### "PlatformException: No implementation found"
**Årsak:** Firebase ikke initialisert
**Løsning:** Sikre Firebase.initializeApp() kjøres i main()

### "PERMISSION_DENIED" i Firestore
**Årsak:** Security rules ikke satt opp
**Løsning:** 
1. Firebase Console → Firestore → Rules
2. Lim inn reglene fra `FIRESTORE_SECURITY_RULES.md`
3. Klikk "Publish"

### Innlogging fungerer ikke
**Årsak:** Firebase credentials feil
**Løsning:**
1. Verifiser `firebase_options.dart` har korrekte credentials
2. Sjekk at `google-services.json` er i `android/app/`
3. Kjør `flutter clean` og `flutter pub get`

### Data synkroniseres ikke til skyen
**Årsak:** Offline mode eller auth issue
**Løsning:**
1. Sjekk at bruker er logget inn (AuthService.currentUser != null)
2. Sjekk nettverkstilkobling
3. Sjekk OfflineModeManager.pendingOperations for køet

---

## Neste Steg

1. **Firebase Setup** - Fullfør konfigurering hvis ønsket
2. **Test alle features** - Login, opprett data, test offline
3. **Deployment** - Build APK/IPA for distribusjon
4. **Branding** - Oppdater app-navn, logo, farger
5. **Multi-bruker** - Test deling med andre brukere

---

## Viktige Filer

- `lib/main.dart` - App-entry point
- `lib/services/` - Business logic (Auth, Sync, etc)
- `lib/screens/` - UI-screens
- `lib/models/` - Data models (Hive)
- `firebase_options.dart` - Firebase config
- `pubspec.yaml` - Dependencies

---

## Dokumentasjon

- **Firebase Setup:** Se `FIREBASE_SETUP.md`
- **Security Rules:** Se `FIRESTORE_SECURITY_RULES.md`
- **Multi-user:** Se `MULTI_USER_SETUP.md`
- **Navigation:** Se `NAVIGATION_SUMMARY.md`

---

## Support

Hvis du møter problemer:
1. Sjekk Flutter version: `flutter --version`
2. Run: `flutter doctor -v`
3. Sjekk logs: `flutter run -v`
4. Søk i dokumentasjon over

**Versjon:** 1.0.0  
**Sist oppdatert:** 27. Januar 2026
