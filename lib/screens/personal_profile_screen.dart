import 'package:flutter/material.dart';

class PersonalProfileScreen extends StatelessWidget {
  const PersonalProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Personal profile')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Personal profile editing is not available in this build.'),
        ),
      ),
    );
  }
}
