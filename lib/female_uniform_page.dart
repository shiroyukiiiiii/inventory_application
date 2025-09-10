import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FemaleUniformPage extends StatelessWidget {
  final User user;

  const FemaleUniformPage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Female Uniform')),
      body: Center(
        child: Text(
          'Hello, ${user.displayName ?? 'Student'}! This is the Female Uniform Page.',
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
