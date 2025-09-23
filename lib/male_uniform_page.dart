import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'uniform_preview_page.dart';

class MaleUniformPage extends StatelessWidget {
  final User user;

  const MaleUniformPage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Male Uniform')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Please select your course:',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UniformPreviewPage(
                          user: user,
                          initialGender: 'Male',
                          initialCourse: 'BSCRIM',
                        ),
                      ),
                    );
                  },
                  child: const Text('BSCRIM'),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UniformPreviewPage(
                          user: user,
                          initialGender: 'Male',
                          initialCourse: 'ABCOM',
                        ),
                      ),
                    );
                  },
                  child: const Text('ABCOM'),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UniformPreviewPage(
                          user: user,
                          initialGender: 'Male',
                          initialCourse: 'BSCS',
                        ),
                      ),
                    );
                  },
                  child: const Text('BSCS'),
                ),
              ],
            ),
            const SizedBox(height: 30),
            Text(
              'Hello, ${user.displayName ?? 'Student'}! '
              'This is the Male Uniform Page.',
              style: const TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}
