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
        child: ElevatedButton(
          onPressed: onSignIn,
          child: const Text('Sign in'),
        ),
      ),
    );
  }
}
