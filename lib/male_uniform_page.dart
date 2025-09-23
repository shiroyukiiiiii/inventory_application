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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Please select your course:',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),

            // Three Buttons Row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UniformPreviewPage(
                          gender: 'Male',
                          course: 'BSCRIM',
                          user: user,
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
                          gender: 'Male',
                          course: 'ABCOM',
                          user: user,
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
                          gender: 'Male',
                          course: 'BSCS',
                          user: user,
                        ),
                      ),
                    );
                  },
                  child: const Text('BSCS'),
                ),
              ],
            ),
          ],
=======
        child: Text(
          'Hello, ${user.displayName ?? 'Student'}! This is the Male Uniform Page.',
          style: const TextStyle(fontSize: 18),
>>>>>>> mainfeatures
        ),
      ),
    );
  }
}
