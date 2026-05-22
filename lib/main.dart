import 'dart:async';
import 'dart:ui';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:breedly/generated_l10n/app_localizations.dart';
import 'package:breedly/screens/main_navigation_screen.dart';
import 'package:breedly/screens/login_screen.dart';
import 'package:breedly/screens/sign_up_screen.dart';
import 'package:breedly/screens/onboarding_screen.dart';
import 'package:breedly/screens/web_landing_screen.dart';
import 'package:breedly/services/subscription_service.dart';
import 'package:breedly/screens/paywall_screen.dart';
import 'package:breedly/utils/hive_initializer.dart';
import 'package:breedly/utils/notification_service.dart';
import 'package:breedly/providers/language_provider.dart';
import 'package:breedly/providers/theme_provider.dart';
import 'package:breedly/providers/kennel_provider.dart';
import 'package:breedly/services/auth_service.dart';
import 'package:breedly/services/offline_mode_manager.dart';
import 'package:breedly/services/web_push_service.dart';
import 'package:breedly/services/fcm_token_service.dart';
import 'package:breedly/services/cloud_sync_service.dart';
import 'package:breedly/providers/subscription_provider.dart';
import 'package:breedly/providers/progesterone_unit_provider.dart';
import 'package:breedly/widgets/startup_gate.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:breedly/services/web_reload_stub.dart'
    if (dart.library.html) 'package:breedly/services/web_reload_web.dart' as web_reload;
import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize date formatting for all supported locales
  await initializeDateFormatting('nb');
  await initializeDateFormatting('sv');
  await initializeDateFormatting('da');
  await initializeDateFormatting('fi');
  await initializeDateFormatting('en');

  // Catch all unhandled async errors so they don't silently kill the app
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('UNHANDLED ERROR: $error');
    debugPrint('Stack: $stack');
    return true; // Prevent the error from propagating
  };

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
                const Icon(LucideIcons.alertCircle, color: Colors.red, size: 48),
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
  
  // Configure system UI overlay style (skip on web - not applicable)
  if (!kIsWeb) {
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
  }
  
  // Initialize Firebase for all supported platforms
  try {
    debugPrint('Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized OK');
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
    // Continue anyway - app will work offline
  }

  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  // Existing screens still read Hive boxes directly; initialize them before UI.
  await Hive.initFlutter();
  try {
    await initializeHive();
  } catch (e) {
    debugPrint('Hive initialization error: $e');
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

  final offlineModeManager = OfflineModeManager();
  try {
    await offlineModeManager.initialize();
  } catch (e) {
    debugPrint('OfflineModeManager initialization error: $e');
  }
  
  // Enable Firestore offline persistence as the sole offline mechanism.
  try {
    FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);
  } catch (e) {
    debugPrint('Firestore persistence error: $e');
  }

  // Initialize theme provider
  final themeProvider = ThemeProvider();
  try {
    await themeProvider.initialize();
  } catch (e) {
    debugPrint('ThemeProvider initialization error: $e');
  }

  // Initialize kennel provider
  final kennelProvider = KennelProvider();

  // Initialize subscription provider
  final subscriptionProvider = SubscriptionProvider();

  final languageProvider = LanguageProvider();

  // Initialize progesterone unit provider
  final progesteroneUnitProvider = ProgesteroneUnitProvider();

  debugPrint('Starting app...');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: languageProvider),
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: kennelProvider),
        ChangeNotifierProvider.value(value: subscriptionProvider),
        ChangeNotifierProvider.value(value: progesteroneUnitProvider),
        Provider.value(value: offlineModeManager),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late AuthService _authService;
  String? _initializedForUserId;
  StreamSubscription<User?>? _authListener;
  Timer? _webVersionTimer;
  String? _currentWebVersion;
  bool _webUpdatePromptShown = false;

  @override
  void initState() {
    super.initState();
    _authService = AuthService();
    if (kIsWeb) {
      _startWebVersionChecks();
    }
    if (kIsWeb) {
      // Handle any pending Google redirect sign-in result
      _authService.handleGoogleRedirectResult();
      _authListener = _authService.authStateChanges.listen((user) async {
        if (user != null) {
          await WebPushService().onUserSignedIn();
        } else {
          await WebPushService().onUserSignedOut();
        }
      });
    } else {
      _authListener = _authService.authStateChanges.listen((user) async {
        if (user != null) {
          await FcmTokenService().onUserSignedIn();
        } else {
          await FcmTokenService().onUserSignedOut();
        }
      });
    }
  }

  @override
  void dispose() {
    _authListener?.cancel();
    _webVersionTimer?.cancel();
    super.dispose();
  }

  Future<void> _startWebVersionChecks() async {
    await _checkForWebUpdate(initial: true);
    _webVersionTimer?.cancel();
    _webVersionTimer = Timer.periodic(
      const Duration(minutes: 3),
      (_) => _checkForWebUpdate(),
    );
  }

  Future<void> _checkForWebUpdate({bool initial = false}) async {
    if (!kIsWeb || !mounted) return;
    try {
      final uri = Uri.parse('/version.json?v=${DateTime.now().millisecondsSinceEpoch}');
      final response = await http
          .get(
            uri,
            headers: const {
              'Cache-Control': 'no-cache',
              'Pragma': 'no-cache',
            },
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) return;
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final remoteVersion = (json['version'] as String?)?.trim();
      if (remoteVersion == null || remoteVersion.isEmpty) return;

      if (_currentWebVersion == null || initial) {
        _currentWebVersion = remoteVersion;
        return;
      }

      if (_currentWebVersion != remoteVersion && !_webUpdatePromptShown) {
        _webUpdatePromptShown = true;
        _showWebUpdatePrompt();
      }
    } catch (_) {
      // Silent fail: update-check must never impact app usability.
    }
  }

  Future<void> _runIdentityRepairIfDue(User user) async {
    final email = (user.email ?? '').trim();
    if (email.isEmpty) return;
    try {
      final sync = FirestoreService();
      await sync.repairUserIdentityOnServer();
      await sync.recoverOwnershipFromEmail(
        userId: user.uid,
        userEmail: email,
      );
    } catch (_) {
      // Non-fatal: should never block app startup.
    }
  }

  void _showWebUpdatePrompt() {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Update available'),
        content: Text(
          'A new version of Peddex is available. Reload now to get the latest updates.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _webUpdatePromptShown = false;
            },
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              web_reload.reloadPage();
            },
            child: const Text('Reload now'),
          ),
        ],
      ),
    );
  }

  Widget _buildWebLanding(BuildContext context) {
    return WebLandingScreen(
      onSignIn: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const _WebLoginScreen()),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final kennelProvider = context.read<KennelProvider>();
    final subscriptionProvider = context.read<SubscriptionProvider>();

    return MaterialApp(
      title: 'PEDDEX',
      debugShowCheckedModeBanner: false,
      showPerformanceOverlay: false,
      checkerboardRasterCacheImages: false,
      checkerboardOffscreenLayers: false,
      showSemanticsDebugger: false,
      debugShowMaterialGrid: false,
      locale: languageProvider.currentLocale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: languageProvider.supportedLocales,
      theme: themeProvider.buildTheme(),
      // Respect system/browser text scaling preferences.
      builder: (context, child) {
        return child!;
      },
      home: kIsWeb
        // Web: check auth state and whitelist
        ? StreamBuilder<User?>(
            stream: _authService.authStateChanges,
            builder: (context, snapshot) {
              // Loading state
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              // Check if user is logged in and whitelisted
              if (snapshot.hasData && snapshot.data != null) {
                final user = snapshot.data!;
                const allowedEmails = {
                  'kjetilandre95@gmail.com',
                  'bard.skalstad@gmail.com',
                  'jennywesterby16@gmail.com',
                  'katrinewesterby71@gmail.com',
                };
                
                // Verify whitelist
                if (allowedEmails.contains(user.email?.toLowerCase())) {
                  // Initialize kennel provider when user logs in
                  if (_initializedForUserId != user.uid) {
                    _initializedForUserId = user.uid;
                    WidgetsBinding.instance.addPostFrameCallback((_) async {
                      await subscriptionProvider.initialize(user.uid);

                      // Await kennel initialization
                      await kennelProvider.initialize(user.uid, user.email ?? '');

                      // Ensure legacy nested Firestore data is promoted to the
                      // new flat collections (ownerId/kennelId fields) so
                      // screens that query flat paths can see existing records.
                      await FirestoreService().migrateToFlatCollections(user.uid);
                      unawaited(_runIdentityRepairIfDue(user));
                    });
                  }
                  return const MainNavigationScreen();
                } else {
                  // Not whitelisted - sign out and show landing
                  WidgetsBinding.instance.addPostFrameCallback((_) async {
                    await _authService.signOut();
                  });
                  return _buildWebLanding(context);
                }
              }

              // Not logged in - show landing screen
              return _buildWebLanding(context);
            },
          )
        : StartupGate(
            authService: _authService,
            isSubscribedStream: SubscriptionService().isSubscribed,
            paywallBuilder: (context, user) => PaywallScreen(
              allowDismiss: false,
              onDismissed: () {},
              onSubscribed: () async {
                await subscriptionProvider.refreshStatus();
                setState(() {});
              },
            ),
            onAuthenticated: (user) async {
              await subscriptionProvider.initialize(user.uid);

              // Block app content until kennel context is loaded.
              await kennelProvider.initialize(user.uid, user.email ?? '');

              // Keep migration + repair in startup flow after kennel is ready.
              await FirestoreService().migrateToFlatCollections(user.uid);
              unawaited(_runIdentityRepairIfDue(user));
            },
            authenticatedBuilder: (context, user) => const _AuthenticatedHome(),
            unauthenticatedBuilder: (context) => LoginScreen(
              onLoginSuccess: () {
                setState(() {});
              },
            ),
          ),
      routes: {
        '/signup': (context) => SignUpScreen(
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
  const _AuthenticatedHome();

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
    return const MainNavigationScreen();
  }
}

/// Shown on web — the web version is under development.
// ignore: unused_element
class _WebComingSoonScreen extends StatelessWidget {
  const _WebComingSoonScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.construction,
                    size: 72,
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.6),
                  ),
                  const Gap(24),
                  Text(
                    'Peddex',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Gap(12),
                  Text(
                    'Webversjonen er under utvikling og er ikke tilgjengelig ennå.\nLast ned appen på Android eller iOS for å bruke Peddex.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                  ),
                  const Gap(8),
                  Text(
                    'The web version is under development and not yet available.\nDownload the app on Android or iOS to use Peddex.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[500],
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Discrete developer login button in bottom-right corner
          Positioned(
            bottom: 16,
            right: 16,
            child: IconButton(
              icon: Icon(
                LucideIcons.lock,
                color: Colors.grey[400],
                size: 20,
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const _WebLoginScreen(),
                  ),
                );
              },
              tooltip: 'Developer Access',
            ),
          ),
        ],
      ),
    );
  }
}

/// Web login screen for developer access
class _WebLoginScreen extends StatefulWidget {
  const _WebLoginScreen();

  @override
  State<_WebLoginScreen> createState() => _WebLoginScreenState();
}

class _WebLoginScreenState extends State<_WebLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isRedirecting = false;
  String? _errorMessage;

  // Whitelist emails
  static const Set<String> _allowedEmails = {
    'kjetilandre95@gmail.com',
    'bard.skalstad@gmail.com',
    'jennywesterby16@gmail.com',
    'katrinewesterby71@gmail.com',
  };

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim().toLowerCase();
    
    // Check whitelist
    if (!_allowedEmails.contains(email)) {
      setState(() {
        _errorMessage = 'This is an invite-only beta. Your email is not on the access list.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await AuthService().signInWithEmail(
        email: email,
        password: _passwordController.text,
      );
      
      if (mounted) {
        // Pop back - StreamBuilder in main will handle showing the main app
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        if (e.toString().contains('user-not-found')) {
          _errorMessage = 'No account found for that email address.';
        } else if (e.toString().contains('wrong-password')) {
          _errorMessage = 'Incorrect password. Please try again.';
        } else if (e.toString().contains('invalid-email')) {
          _errorMessage = 'Invalid email address.';
        } else {
          _errorMessage = 'Sign in failed. Please try again.';
        }
      });
    }
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim().toLowerCase();
    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _errorMessage = 'Enter your email address above first, then tap Forgot password.';
      });
      return;
    }
    try {
      await AuthService().sendPasswordResetEmail(email);
      if (mounted) {
        setState(() {
          _errorMessage = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Password reset email sent. Check your inbox.',
            ),
            backgroundColor: Colors.green[700],
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not send reset link. Check the email address and try again.';
      });
    }
  }

  Future<void> _handleGoogleLogin() async {
    setState(() {
      _isLoading = true;
      _isRedirecting = true;
      _errorMessage = null;
    });

    try {
      // signInWithRedirect navigates the page away to Google — no popup needed
      await AuthService().signInWithGoogle();
      // This line is unreachable on web (page navigates away)
    } catch (e) {
      final error = e.toString();
      if (error.contains('google-sign-in-redirecting')) {
        // Expected — browser is navigating to Google, nothing to do
        return;
      }
      setState(() {
        _isLoading = false;
        _isRedirecting = false;
        if (error.contains('google-sign-in-cancelled')) {
          _errorMessage = 'Google sign-in was cancelled.';
        } else {
          _errorMessage = 'Google sign-in failed. Please try again.';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Peddex'),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        'assets/Peddex app logo ny 1024x1024.png',
                        width: 72,
                        height: 72,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                    const Gap(20),
                    Text(
                      'Sign in to Peddex',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const Gap(8),
                    Text(
                      'Early access — invite only',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[500],
                      ),
                    ),
                    const Gap(32),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: const Icon(LucideIcons.mail),
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email address.';
                        }
                        if (!value.contains('@')) {
                          return 'Invalid email address.';
                        }
                        return null;
                      },
                    ),
                    const Gap(16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(LucideIcons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password.';
                        }
                        return null;
                      },
                    ),
                    const Gap(8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _isLoading ? null : _handleForgotPassword,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey[600],
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Forgot password?',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                    if (_errorMessage != null) ...[
                      const Gap(16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red[300]!),
                        ),
                        child: Row(
                          children: [
                            Icon(LucideIcons.alertCircle, color: Colors.red[700], size: 20),
                            const Gap(8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(
                                  color: Colors.red[700],
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const Gap(24),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'Sign in',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    const Gap(24),
                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey[300])),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'or',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: Colors.grey[300])),
                      ],
                    ),
                    const Gap(24),
                    SizedBox(
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : _handleGoogleLogin,
                        icon: _isRedirecting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Center(
                                  child: Text(
                                    'G',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ),
                        label: Text(
                          _isRedirecting
                              ? 'Redirecting to Google...'
                              : 'Continue with Google',
                          style: const TextStyle(fontSize: 14),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.black87,
                          side: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
