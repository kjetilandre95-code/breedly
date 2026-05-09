import 'package:flutter/material.dart';

class WebLandingScreen extends StatelessWidget {
  final VoidCallback onSignIn;

  const WebLandingScreen({
    super.key,
    required this.onSignIn,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Breedly', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 12),
              const Text('Manage your kennel from one place.'),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: onSignIn,
                child: const Text('Sign in'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
