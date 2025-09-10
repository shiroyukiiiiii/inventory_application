import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'homepage.dart';
import 'admin_login_page.dart';
import 'admin_dashboard.dart';
import 'inventory_page.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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
      navigatorKey: navigatorKey, // <-- navigatorKey
      title: 'Google Sign-In Web',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const InventoryPage(),
      debugShowCheckedModeBanner: false,
      routes: {
        '/admin-login': (context) => const AdminLoginPage(),
        '/admin-inventory': (context) => const InventoryPage(),
        '/admin-dashboard': (context) => const AdminDashboard(),
      },
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _signInWithPopup,
              child: const Text('Sign in with Google'),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.admin_panel_settings),
              label: const Text('Admin Login'),
              onPressed: () {
                // Use navigatorKey safely
                navigatorKey.currentState?.pushNamed('/admin-login');
              },
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

      if (!mounted) return; // Ensure widget is still mounted

      _user = userCredential.user;

      if (_user != null) {
        navigatorKey.currentState?.pushReplacement(
          MaterialPageRoute(builder: (_) => HomePage(user: _user!)),
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error: $e'); // Safe use of context
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
