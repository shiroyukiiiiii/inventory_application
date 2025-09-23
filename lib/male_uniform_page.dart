import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main.dart';
import 'uniform_preview_page.dart';

class MaleUniformPage extends StatelessWidget {
  final User user;

  const MaleUniformPage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Home Page'),
            const SizedBox(width: 10),
            CircleAvatar(
              backgroundImage: NetworkImage(user.photoURL ?? ''),
              radius: 15,
            ),
            const SizedBox(width: 5),
            Text(
              user.displayName ?? '',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              FirebaseAuth.instance.signOut().then((_) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const SignInPage()),
                  (Route<dynamic> route) => false,
                );
              });
            },
          ),
        ],
      ),
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
        ),
      ),
    );
  }
}
