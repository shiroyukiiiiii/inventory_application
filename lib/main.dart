import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:inventory_application/admin_dashboard.dart';
import 'homepage.dart';
import 'admin_login_page.dart';
import 'uniform_list_page.dart';
import 'adminregistration.dart';

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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
        textTheme: const TextTheme(
          bodyMedium: TextStyle(fontFamily: 'Poppins'),
        ),
      ),
      home: const SignInPage(),
      debugShowCheckedModeBanner: false,
      routes: {
        '/admin-login': (context) => const AdminLoginPage(),
        '/admin-inventory': (context) => const UniformListPage(),
        '/admin-register': (context) => const AdminRegisterPage(),
        '/admin-dashboard': (context) => const AdminDashboardApp(),
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
      appBar: AppBar(
        title: const Text(
          'Uniform Management System',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 3,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade300, Colors.blue.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Card(
            elevation: 10,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            color: Colors.white.withOpacity(0.97),
            margin: const EdgeInsets.symmetric(horizontal: 24),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 45, horizontal: 30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 🔹 Logo Image (Make sure your image path is correct)
                  Icon(
                    Icons.school_sharp,
                    size: 100, // Adjust the size
                    color: Colors.blue.shade700, // Adjust color
                  ),

                  const Text(
                    'Welcome to SIASU System',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Please sign in to continue',
                    style: TextStyle(color: Colors.black54, fontSize: 15),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 35),

                  // 🔹 Google Sign-In Button
                  ElevatedButton.icon(
                    icon: const Icon(Icons.login, color: Colors.white),
                    label: const Text(
                      'Sign in with Google',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 25),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                    ),
                    onPressed: _signInWithPopup,
                  ),

                  const SizedBox(height: 20),

                  // 🔹 Admin Login Button (Fixed syntax)
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 🔹 Firebase Google Sign-In Function
  Future<void> _signInWithPopup() async {
    try {
      final provider = GoogleAuthProvider();
      final userCredential =
          await FirebaseAuth.instance.signInWithPopup(provider);

      setState(() {
        _user = userCredential.user;
      });

      if (_user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage(user: _user!)),
        );
      }
    } catch (e) {
      _showSnackBar('Error: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
