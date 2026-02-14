import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:breedly/generated_l10n/app_localizations.dart';
import 'package:breedly/screens/main_navigation_screen.dart';
import 'package:breedly/screens/login_screen.dart';
import 'package:breedly/screens/sign_up_screen.dart';
import 'package:breedly/screens/onboarding_screen.dart';
import 'package:breedly/utils/hive_initializer.dart';
import 'package:breedly/utils/notification_service.dart';
import 'package:breedly/providers/language_provider.dart';
import 'package:breedly/providers/theme_provider.dart';
import 'package:breedly/providers/kennel_provider.dart';
import 'package:breedly/services/auth_service.dart';
import 'package:breedly/services/offline_mode_manager.dart';
import 'package:breedly/services/cloud_sync_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set up error handling for release mode
  // In release mode, Flutter shows an empty grey box when a widget fails.
  // Override this to show a user-friendly fallback instead.
  if (!kDebugMode) {
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      debugPrint('Flutter error: ${details.exception}');
      debugPrint('Stack trace: ${details.stack}');
    };
    ErrorWidget.builder = (FlutterErrorDetails details) {
      return Material(
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Noe gikk galt',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Prøv å gå tilbake og prøv igjen.\n${details.exception}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    };
  }
  
  // Configure system UI overlay style (hide navigation bar icons)
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
    overlays: [SystemUiOverlay.top],
  );
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  
  // Initialize Firebase for all supported platforms
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
    // Continue anyway - app will work offline
  }

  // Initialize Hive
  await Hive.initFlutter();
  try {
    await initializeHive();
  } catch (e) {
    debugPrint('Hive initialization error: $e');
    // Try reinitializing without deleting data
    try {
      await initializeHive();
    } catch (e2) {
      debugPrint('Hive re-initialization error: $e2');
    }
  }
  
  // Initialize notifications (wrapped in try-catch for release safety)
  try {
    await NotificationService().initialize();
  } catch (e) {
    debugPrint('Notification initialization error: $e');
  }
  
  // Initialize offline mode manager
  final offlineModeManager = OfflineModeManager();
  try {
    await offlineModeManager.initialize();
  } catch (e) {
    debugPrint('OfflineModeManager initialization error: $e');
  }

  // Enable offline persistence for Firestore
  try {
    final cloudSyncService = CloudSyncService();
    await cloudSyncService.enableOfflinePersistence();
  } catch (e) {
    debugPrint('Firestore persistence error: $e');
  }

  // Initialize theme provider
  final themeProvider = ThemeProvider();
  await themeProvider.initialize();

  // Initialize kennel provider
  final kennelProvider = KennelProvider();

  runApp(MyApp(
    languageProvider: LanguageProvider(),
    themeProvider: themeProvider,
    offlineModeManager: offlineModeManager,
    kennelProvider: kennelProvider,
  ));
}

class MyApp extends StatefulWidget {
  final LanguageProvider languageProvider;
  final ThemeProvider themeProvider;
  final OfflineModeManager offlineModeManager;
  final KennelProvider kennelProvider;

  const MyApp({
    super.key,
    required this.languageProvider,
    required this.themeProvider,
    required this.offlineModeManager,
    required this.kennelProvider,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late AuthService _authService;
  VoidCallback? _languageListener;
  VoidCallback? _themeListener;
  VoidCallback? _kennelListener;
  String? _initializedForUserId;

  @override
  void initState() {
    super.initState();
    _authService = AuthService();
    _languageListener = () {
      if (!mounted) return;
      setState(() {});
    };
    _themeListener = () {
      if (!mounted) return;
      setState(() {});
    };
    _kennelListener = () {
      if (!mounted) return;
      setState(() {});
    };
    widget.languageProvider.addListener(_languageListener!);
    widget.themeProvider.addListener(_themeListener!);
    widget.kennelProvider.addListener(_kennelListener!);
  }

  @override
  void dispose() {
    if (_languageListener != null) {
      widget.languageProvider.removeListener(_languageListener!);
    }
    if (_themeListener != null) {
      widget.themeProvider.removeListener(_themeListener!);
    }
    if (_kennelListener != null) {
      widget.kennelProvider.removeListener(_kennelListener!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Breedly',
      debugShowCheckedModeBanner: false,
      showPerformanceOverlay: false,
      checkerboardRasterCacheImages: false,
      checkerboardOffscreenLayers: false,
      showSemanticsDebugger: false,
      debugShowMaterialGrid: false,
      locale: widget.languageProvider.currentLocale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: widget.languageProvider.supportedLocales,
      theme: widget.themeProvider.buildTheme(),
      darkTheme: widget.themeProvider.buildDarkTheme(),
      themeMode: widget.themeProvider.useSystemTheme 
          ? ThemeMode.system 
          : (widget.themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light),
      home: StreamBuilder<User?>(
        stream: _authService.idTokenChanges,
        builder: (context, snapshot) {
          // If connection state is waiting, show loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          // If user is logged in, show home screen
          if (snapshot.hasData && snapshot.data != null) {
            final user = snapshot.data!;
            // Initialize kennel provider when user logs in (only once per user)
            if (_initializedForUserId != user.uid) {
              _initializedForUserId = user.uid;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                widget.kennelProvider.initialize(user.uid, user.email ?? '');
              });
            }
            
            return _AuthenticatedHome(
              languageProvider: widget.languageProvider,
              themeProvider: widget.themeProvider,
              kennelProvider: widget.kennelProvider,
              offlineModeManager: widget.offlineModeManager,
            );
          }

          // User is logged out, reset initialization state
          _initializedForUserId = null;

          // Otherwise, show login screen
          return LoginScreen(
            languageProvider: widget.languageProvider,
            onLoginSuccess: () {
              setState(() {});
            },
          );
        },
      ),
      routes: {
        '/signup': (context) => SignUpScreen(
          languageProvider: widget.languageProvider,
          onSignUpSuccess: () {
            setState(() {});
          },
        ),
      },
    );
  }
}

/// Wrapper widget that handles onboarding flow for authenticated users
class _AuthenticatedHome extends StatefulWidget {
  final LanguageProvider languageProvider;
  final ThemeProvider themeProvider;
  final KennelProvider kennelProvider;
  final OfflineModeManager offlineModeManager;

  const _AuthenticatedHome({
    required this.languageProvider,
    required this.themeProvider,
    required this.kennelProvider,
    required this.offlineModeManager,
  });

  @override
  State<_AuthenticatedHome> createState() => _AuthenticatedHomeState();
}

class _AuthenticatedHomeState extends State<_AuthenticatedHome> {
  bool? _onboardingCompleted;

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final completed = await OnboardingScreen.isCompleted();
    if (mounted) {
      setState(() {
        _onboardingCompleted = completed;
      });
    }
  }

  void _onOnboardingComplete() {
    setState(() {
      _onboardingCompleted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show loading while checking onboarding status
    if (_onboardingCompleted == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Show onboarding if not completed
    if (!_onboardingCompleted!) {
      return OnboardingScreen(
        onComplete: _onOnboardingComplete,
      );
    }

    // Show main navigation
    return MainNavigationScreen(
      languageProvider: widget.languageProvider,
      themeProvider: widget.themeProvider,
      kennelProvider: widget.kennelProvider,
      offlineModeManager: widget.offlineModeManager,
    );
  }
}
