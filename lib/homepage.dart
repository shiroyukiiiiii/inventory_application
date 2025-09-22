import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'male_uniform_page.dart';
import 'female_uniform_page.dart';
import 'student_manage_requests_page.dart';
import 'main.dart'; // SignInPage

class HomePage extends StatelessWidget {
  final User user;

  const HomePage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Home Page'),
            const SizedBox(width: 10),
            CircleAvatar(
              backgroundImage: NetworkImage(user.photoURL ?? ''),
              radius: 15,
            ),
            const SizedBox(width: 5),
            Text(user.displayName ?? '', style: const TextStyle(fontSize: 16)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const SignInPage()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Welcome! Please select an option:',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MaleUniformPage(user: user),
                  ),
                );
              },
              child: const Text('Male Uniform'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FemaleUniformPage(user: user),
                  ),
                );
              },
              child: const Text('Female Uniform'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StudentManageRequestsPage(user: user),
                  ),
                );
              },
              child: const Text('Manage My Requests'),
            ),
          ],
        ),
      ),
    );
  }
}
