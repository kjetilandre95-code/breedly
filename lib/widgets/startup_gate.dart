import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:breedly/providers/kennel_provider.dart';
import 'package:breedly/providers/subscription_provider.dart';
import 'package:breedly/services/auth_service.dart';
import 'package:provider/provider.dart';

typedef AuthenticatedBuilder = Widget Function(BuildContext context, User user);
typedef UnauthenticatedBuilder = Widget Function(BuildContext context);
typedef PaywallBuilder = Widget Function(BuildContext context, User user);
typedef UserInitCallback = Future<void> Function(User user);
typedef UserGuard = bool Function(User user);

/// Blocks app startup until:
/// 1) auth state is resolved
/// 2) authenticated user is initialized
/// 3) kennel context loading has completed
class StartupGate extends StatefulWidget {
  final AuthService authService;
  final UserInitCallback onAuthenticated;
  final AuthenticatedBuilder authenticatedBuilder;
  final UnauthenticatedBuilder unauthenticatedBuilder;
  final PaywallBuilder paywallBuilder;
  final UserGuard? guard;

  const StartupGate({
    super.key,
    required this.authService,
    required this.onAuthenticated,
    required this.authenticatedBuilder,
    required this.unauthenticatedBuilder,
    required this.paywallBuilder,
    this.guard,
  });

  @override
  State<StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<StartupGate> {
  String? _initializedUserId;
  bool _isInitializing = false;

  Future<void> _ensureInitialized(User user) async {
    if (_initializedUserId == user.uid || _isInitializing) return;
    _isInitializing = true;
    try {
      await widget.onAuthenticated(user);
      if (mounted) {
        setState(() {
          _initializedUserId = user.uid;
        });
      }
    } finally {
      _isInitializing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: widget.authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _StartupLoadingScreen();
        }

        final user = snapshot.data;
        if (user == null) {
          _initializedUserId = null;
          return widget.unauthenticatedBuilder(context);
        }

        if (widget.guard != null && !widget.guard!(user)) {
          _initializedUserId = null;
          return widget.unauthenticatedBuilder(context);
        }

        if (_initializedUserId != user.uid) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _ensureInitialized(user);
          });
          return const _StartupLoadingScreen();
        }

        return Consumer<KennelProvider>(
          builder: (context, kennelProvider, _) {
            if (kennelProvider.isLoading || _isInitializing) {
              return const _StartupLoadingScreen();
            }
            if (kDebugMode) {
              return widget.authenticatedBuilder(context, user);
            }
            final subscriptionProvider = context.watch<SubscriptionProvider>();
            if (subscriptionProvider.isLoading ||
                !subscriptionProvider.isInitialized) {
              return const _StartupLoadingScreen();
            }
            if (!subscriptionProvider.isPremium) {
              return widget.paywallBuilder(context, user);
            }
            return widget.authenticatedBuilder(context, user);
          },
        );
      },
    );
  }
}

class _StartupLoadingScreen extends StatelessWidget {
  const _StartupLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
