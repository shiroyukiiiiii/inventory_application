import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MaleUniformPage extends StatelessWidget {
  final User user;

  const MaleUniformPage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Male Uniform')),
      body: Center(
        child: Text(
          'Hello, ${user.displayName ?? 'Student'}! This is the Male Uniform Page.',
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
