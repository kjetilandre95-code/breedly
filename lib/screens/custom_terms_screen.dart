import 'package:flutter/material.dart';

class CustomTermsScreen extends StatelessWidget {
  const CustomTermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Custom terms')),
      body: const Center(
        child: Text('Custom contract terms are not available in this build.'),
      ),
    );
  }
}
