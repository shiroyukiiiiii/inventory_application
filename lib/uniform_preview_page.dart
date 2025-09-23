import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'uniform_request_page.dart';

class UniformPreviewPage extends StatelessWidget {
  final String gender;
  final String course;
  final User user;

  const UniformPreviewPage({super.key, required this.gender, required this.course, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$gender Uniform Preview - $course'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              gender == 'Male' ? Icons.male : Icons.female,
              size: 100,
            ),
            const SizedBox(height: 20),
            Text(
              '$gender Uniform for $course',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text(
              'Uniform preview and details go here.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              icon: const Icon(Icons.request_page),
              label: const Text('Request Uniform'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UniformRequestPage(
                      user: user,
                      initialGender: gender,
                      initialCourse: course,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}