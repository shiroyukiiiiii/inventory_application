import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomePage extends StatelessWidget {
  final User user;

  const HomePage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Welcome Student!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text(
              'Please select your gender:',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            

            // Two Buttons Row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Male Pressed')),
                    );
                  },
                  child: const Text('Male'),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Female Pressed')),
                    );
                  },
                  child: const Text('Female'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
