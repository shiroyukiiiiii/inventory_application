import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StudentManageRequestsPage extends StatelessWidget {
  final User user;

  const StudentManageRequestsPage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage My Requests')),
      body: Center(
        child: Text(
          'Hello, ${user.displayName ?? 'Student'}! Here you can manage your requests.',
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
