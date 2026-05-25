import 'package:flutter/material.dart';

class CustomTermsScreen extends StatelessWidget {
  const CustomTermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Custom Terms')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Custom contract terms are not available yet.'),
        ),
      ),
    );
  }
}
