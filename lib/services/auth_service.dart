import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:breedly/services/cloud_sync_service.dart';
import 'package:breedly/utils/logger.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Get current user
  User? get currentUser => _firebaseAuth.currentUser;

  /// Get current user ID
  String? get currentUserId => _firebaseAuth.currentUser?.uid;

  /// Get current user email
  String? get currentUserEmail => _firebaseAuth.currentUser?.email;

  /// Get authentication state stream
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// Get id token changes stream
  Stream<User?> get idTokenChanges => _firebaseAuth.idTokenChanges();

  /// Sign up with email and password
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Set display name
      await userCredential.user?.updateDisplayName(displayName);
      await userCredential.user?.reload();

      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        throw Exception('Passordet er for svakt. Minimum 6 tegn.');
      } else if (e.code == 'email-already-in-use') {
        throw Exception('E-postadressen er allerede registrert.');
      } else if (e.code == 'invalid-email') {
        throw Exception('Ugyldig e-postadresse.');
      } else {
        throw Exception('Feil ved registrering: ${e.message}');
      }
    }
  }

  /// Sign in with email and password
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw Exception('Bruker ikke funnet.');
      } else if (e.code == 'wrong-password') {
        throw Exception('Feil passord.');
      } else if (e.code == 'invalid-email') {
        throw Exception('Ugyldig e-postadresse.');
      } else if (e.code == 'user-disabled') {
        throw Exception('Brukerkontoen er deaktivert.');
      } else {
        throw Exception('Feil ved innlogging: ${e.message}');
      }
    }
  }

  /// Sign in with Google
  Future<UserCredential> signInWithGoogle() async {
    try {
      // Check if Firebase is initialized first
      if (kIsWeb) {
        throw Exception('Google Sign-In er ikke støttet på web. Bruk email og passord i stedet.');
      }
      if (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux) {
        throw Exception(
            'Google Sign-In er ikke støttet på denne plattformen. Bruk email og passord i stedet.');
      }

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw Exception('Google-innlogging ble avbrutt.');
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        throw Exception('Google-autentisering mislyktes. Sjekk Firebase-konfigurering.');
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken!,
        idToken: googleAuth.idToken!,
      );

      final userCredential =
          await _firebaseAuth.signInWithCredential(credential);

      final user = userCredential.user;
      final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;

      if (user != null && isNewUser) {
        final email = user.email ?? googleUser.email;
        try {
          await CloudSyncService().saveUserProfile(
            userId: user.uid,
            email: email,
            displayName:
                user.displayName ?? googleUser.displayName ?? 'Ukjent bruker',
            photoUrl: user.photoURL,
          );
        } catch (e) {
          AppLogger.debug('Feil ved lagring av Google-brukerprofil: $e');
        }
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception('Feil ved Google-innlogging: ${e.message}');
    } catch (e) {
      throw Exception('Feil ved Google-innlogging: $e. Hvis problemet vedvarer, logg inn med email og passord i stedet.');
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _firebaseAuth.signOut();
    } catch (e) {
      throw Exception('Feil ved utlogging: $e');
    }
  }

  /// Check if user is authenticated
  bool get isAuthenticated => _firebaseAuth.currentUser != null;

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw Exception('Bruker ikke funnet.');
      } else {
        throw Exception('Feil: ${e.message}');
      }
    }
  }

  /// Update user profile
  Future<void> updateUserProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        await user.updateDisplayName(displayName ?? user.displayName);
        if (photoUrl != null) {
          await user.updatePhotoURL(photoUrl);
        }
        await user.reload();
      }
    } catch (e) {
      throw Exception('Feil ved oppdatering av profil: $e');
    }
  }

  /// Delete user account
  Future<void> deleteUserAccount() async {
    try {
      await _firebaseAuth.currentUser?.delete();
      await _googleSignIn.signOut();
    } catch (e) {
      throw Exception('Feil ved sletting av konto: $e');
    }
  }

  /// Get ID token
  Future<String?> getIdToken() async {
    try {
      return await _firebaseAuth.currentUser?.getIdToken();
    } catch (e) {
      throw Exception('Feil ved henting av ID token: $e');
    }
  }
}
