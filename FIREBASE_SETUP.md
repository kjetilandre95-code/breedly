# Firebase Authentication & Cloud Sync - Implementasjonsveiledning

## Oversikt

Breedly har nå implementert:
- ✅ Firebase Authentication (Email/Passord + Google Sign-In)
- ✅ Cloud Firestore for skylagring
- ✅ Offline modus med automatisk synkronisering
- ✅ Login og Sign Up screens

## Setup-instruksjoner

### 1. Firebase Konfigurering

#### Steg 1: Opprett Firebase-prosjekt
1. Gå til [Firebase Console](https://console.firebase.google.com)
2. Klikk "Opprett prosjekt"
3. Navn: `breedly`
4. Aktivér Google Analytics (valgfritt)

#### Steg 2: Konfigurer Authentication
1. I Firebase Console, gå til **Authentication**
2. Klikk **Kom i gang**
3. Aktivér disse Sign-in-metodene:
   - Email/Passord
   - Google (trenger Google OAuth 2.0-ID)

#### Steg 3: Konfigurer Firestore Database
1. Gå til **Firestore Database**
2. Klikk **Opprett database**
3. Velg region (f.eks. `europe-west1`)
4. Velg **Start in test mode** (senere oppdater sikkerhet)

#### Steg 4: Hent Firebase-konfigurasjonen
1. Gå til **Project Settings**
2. Under **Your apps**, velg Android/iOS
3. Last ned `google-services.json` (Android) eller `GoogleService-Info.plist` (iOS)

### 2. Oppdater firebase_options.dart

Erstatt de dummykodetene med dine faktiske Firebase-nøkler:

```dart
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'AIzaSyDinYour_REAL_apiKey_Here',
  appId: '1:YOUR_REAL_PROJECT_NUMBER:android:YOUR_REAL_APP_ID',
  messagingSenderId: 'YOUR_REAL_MESSAGING_SENDER_ID',
  projectId: 'your-project-id',
  storageBucket: 'your-project-id.appspot.com',
);
```

### 3. Android-konfigurering

Legg `google-services.json` i `android/app/`:

```
android/
  app/
    google-services.json  ← Legg filen her
```

Oppdater `android/build.gradle`:
```gradle
buildscript {
  dependencies {
    classpath 'com.google.gms:google-services:4.3.15'
  }
}
```

Oppdater `android/app/build.gradle`:
```gradle
apply plugin: 'com.google.gms.google-services'
```

### 4. iOS-konfigurering

1. Legg `GoogleService-Info.plist` i `ios/Runner/`
2. I Xcode: Right-click på `Runner` → **Add Files** → velg `GoogleService-Info.plist`
3. Sikker at den er lagt til under `Runner` target

### 5. Lagre Google-logo (valgfritt)

For bedre Google Sign-in button, last ned og lagre:
```
assets/
  google_logo.png
```

Og legg til i `pubspec.yaml`:
```yaml
flutter:
  assets:
    - assets/google_logo.png
```

## Arkitektur

### AuthService
Håndterer all autentisering:
```dart
final authService = AuthService();

// Opprett bruker
await authService.signUpWithEmail(
  email: 'user@example.com',
  password: 'secure_password',
  displayName: 'Ola Nordmann',
);

// Logg inn
await authService.signInWithEmail(
  email: 'user@example.com',
  password: 'secure_password',
);

// Google Sign-In
await authService.signInWithGoogle();

// Sjekk autentisering
bool isAuth = authService.isAuthenticated;
Stream<User?> authStream = authService.authStateChanges;
```

### CloudSyncService
Håndterer all skylagring og Firestore-synkronisering:
```dart
final cloudSync = CloudSyncService();

// Lagre hund
await cloudSync.saveDog(
  userId: authService.currentUserId!,
  dogId: dog.id,
  dogData: dog.toJson(),
);

// Lagre kull
await cloudSync.saveLitter(
  userId: authService.currentUserId!,
  litterId: litter.id,
  litterData: litter.toJson(),
);

// Hent data i sanntid
cloudSync.littersStream(userId).listen((litters) {
  print('Litters updated: $litters');
});
```

### OfflineModeManager
Håndterer offline/online status og synkronisering:
```dart
final offlineManager = OfflineModeManager();

// Sjekk hvis online
if (offlineManager.isOnline) {
  // Lagre direkte til Firestore
} else {
  // Lagre lokalt og köe for senere
  offlineManager.addPendingOperation(
    id: 'op_123',
    type: 'create',
    collection: 'dogs',
    data: dogData,
    timestamp: DateTime.now(),
  );
}

// Lytt på connection changes
offlineManager.onlineStatusStream.listen((isOnline) {
  if (isOnline) {
    print('Tilbake online - synkroniserer data...');
  }
});
```

## Firestore Database-struktur

```
users/
  {userId}/
    - email: string
    - displayName: string
    - photoUrl: string
    - createdAt: timestamp
    - updatedAt: timestamp
    
    dogs/
      {dogId}/
        - name: string
        - breed: string
        - ...
    
    litters/
      {litterId}/
        - damName: string
        - sireName: string
        - dateOfBirth: timestamp
        - ...
        
        puppies/
          {puppyId}/
            - name: string
            - gender: string
            - ...
    
    income/
      {incomeId}/
        - amount: double
        - date: timestamp
        - ...
    
    expenses/
      {expenseId}/
        - amount: double
        - date: timestamp
        - ...
```

## Firestore Security Rules

Legg disse reglene inn i Firestore Console under **Rules**:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Brukeren kan kun se sin egen data
    match /users/{userId} {
      allow read, write: if request.auth.uid == userId;
      
      match /dogs/{dogId} {
        allow read, write: if request.auth.uid == userId;
      }
      
      match /litters/{litterId} {
        allow read, write: if request.auth.uid == userId;
        
        match /puppies/{puppyId} {
          allow read, write: if request.auth.uid == userId;
        }
      }
      
      match /income/{incomeId} {
        allow read, write: if request.auth.uid == userId;
      }
      
      match /expenses/{expenseId} {
        allow read, write: if request.auth.uid == userId;
      }
    }
  }
}
```

## Offline Modus

Appen fungerer automatisk offline:

1. **Når online**: Data lagres direkte til Firestore
2. **Når offline**: Data lagres lokalt (Hive) + köes i `OfflineModeManager`
3. **Når online igjen**: Alle köede operasjoner synkroniseres automatisk

### Håndter offline i screens

```dart
final offlineManager = OfflineModeManager();

// I din widget
StreamBuilder<bool>(
  stream: offlineManager.onlineStatusStream,
  builder: (context, snapshot) {
    final isOnline = snapshot.data ?? true;
    
    return Column(
      children: [
        if (!isOnline)
          Container(
            color: Colors.orange,
            padding: EdgeInsets.all(8),
            child: Text('Offline mode - data synkroniseres senere'),
          ),
        // Resten av UI
      ],
    );
  },
)
```

## Integrering med eksisterende screens

### HomeScreen
```dart
@override
void initState() {
  super.initState();
  _authService = AuthService();
  
  // Hent data fra Firestore
  if (_authService.isAuthenticated) {
    _loadCloudData();
  }
}

Future<void> _loadCloudData() async {
  final cloudSync = CloudSyncService();
  try {
    final litters = await cloudSync.getLitters(_authService.currentUserId!);
    // Synkroniser med Hive
  } catch (e) {
    print('Error loading data: $e');
  }
}
```

### Lagre data både lokalt og i skyen

```dart
// I add_puppy_screen.dart eller lignende
Future<void> _savePuppy(Puppy puppy) async {
  final puppyBox = Hive.box<Puppy>('puppies');
  
  // Lagre lokalt først
  puppyBox.add(puppy);
  
  // Prøv å lagre til Firestore
  if (_offlineManager.isOnline) {
    final cloudSync = CloudSyncService();
    try {
      await cloudSync.savePuppy(
        userId: _authService.currentUserId!,
        litterId: widget.litter.id,
        puppyId: puppy.id,
        puppyData: puppy.toJson(),
      );
    } catch (e) {
      // Lagres offline og synkroniseres senere
      _offlineManager.addPendingOperation(
        id: puppy.id,
        type: 'create',
        collection: 'puppies',
        data: puppy.toJson(),
        timestamp: DateTime.now(),
      );
    }
  }
}
```

## Testing

### Test lokal autentisering
```dart
void testLogin() async {
  final auth = AuthService();
  try {
    await auth.signUpWithEmail(
      email: 'test@example.com',
      password: 'password123',
      displayName: 'Test User',
    );
    print('Sign up successful!');
  } catch (e) {
    print('Sign up failed: $e');
  }
}
```

### Test offline mode
```dart
void testOfflineMode() async {
  final offlineManager = OfflineModeManager();
  
  // Simuler offline
  await offlineManager.disableNetwork();
  
  // Appen fortsetter å fungere lokalt
  print('Is online: ${offlineManager.isOnline}');
  
  // Simuler online igjen
  await offlineManager.enableNetwork();
  print('Is online: ${offlineManager.isOnline}');
}
```

## Feilsøking

### Firebase not initialized
**Feil**: `MissingPluginException: No implementation found`
**Løsning**: Sikre at Firebase er initialisert i `main()` før `runApp()`

### Google Sign-in ikke fungerer
**Feil**: `PlatformException: com.google.android.gms.common.api.ApiException`
**Løsning**: 
1. Verifiser `google-services.json` er riktig
2. Sjekk SHA-1 fingerprint i Firebase Console
3. Verifiser OAuth-nøkkel er riktig

### Firestore permissions denied
**Feil**: `PlatformException: PERMISSION_DENIED`
**Løsning**:
1. Sjekk Firestore Security Rules
2. Verifiser brukeren er autentisert
3. I test mode - tillat alle (senere gjør strengere)

### Offline data synkroniseres ikke
**Feil**: Pending operasjoner lagres ikke
**Løsning**:
1. Sjekk `OfflineModeManager` er initialisert
2. Verifiser nettverksforbindelse
3. Hent logger med `OfflineModeManager.pendingOperations`

## Neste steg

1. **Integrer CloudSync i alle screens** som lagrer data
2. **Lag sync-indikatorer** i UI for å vise sync-status
3. **Implementer data-merging** for konflikter ved offline operasjoner
4. **Legg til Data Backup** til Google Drive eller iCloud
5. **Implementer sharing** av data mellom brukere

## Ressurser

- [Firebase Documentation](https://firebase.flutter.dev/)
- [Firebase Authentication](https://firebase.google.com/docs/auth)
- [Cloud Firestore](https://firebase.google.com/docs/firestore)
- [Flutter Google Sign-In](https://pub.dev/packages/google_sign_in)
