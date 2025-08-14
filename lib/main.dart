import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyCfppfpgtw3zG_ueshLFkecChTpqZTRCos",
      authDomain: "siasu-223bb.firebaseapp.com",
      projectId: "siasu-223bb",
      storageBucket: "siasu-223bb.appspot.com",
      messagingSenderId: "533072990076",
      appId: "1:533072990076:web:845172bed03cc7e8759ef9",
      measurementId: "G-1DZFV1CT80",
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Google Sign-In Web',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const SignInPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  User? _user;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Google Sign-In Web')),
      body: Center(
        child: _user == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _signInWithPopup,
                    child: const Text('Sign in with Google'),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    backgroundImage: NetworkImage(_user!.photoURL ?? ''),
                    radius: 40,
                  ),
                  const SizedBox(height: 10),
                  Text(_user!.displayName ?? ''),
                  Text(_user!.email ?? ''),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      // First button action
                      _showSnackBar('Button 1 Pressed');
                    },
                    child: const Text('Button 1'),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      // Second button action
                      _showSnackBar('Button 2 Pressed');
                    },
                    child: const Text('Button 2'),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _signOut,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text('Sign Out'),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _signInWithPopup() async {
    try {
      final provider = GoogleAuthProvider();
      final userCredential =
          await FirebaseAuth.instance.signInWithPopup(provider);

      setState(() {
        _user = userCredential.user;
      });

      _showSnackBar('Signed in as ${_user!.displayName}');
    } catch (e) {
      _showSnackBar('Error: $e');
    }
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    setState(() {
      _user = null;
    });
    _showSnackBar('Signed out');
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
//im gay

