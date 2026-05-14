import 'package:flutter/material.dart';

class TrashScreen extends StatelessWidget {
  const TrashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trash')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Trash management is not available in this build.'),
        ),
      ),
    );
  }
}
