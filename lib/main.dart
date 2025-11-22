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
      title: 'Smart Inventory Application for School Uniform',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFF98CB0E)),
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 800;
    final isTablet = screenWidth > 500 && screenWidth <= 800;
    final isPhone = screenWidth <= 500;

    return Scaffold(
     appBar: AppBar(
  elevation: 0,
  backgroundColor: Colors.white,
  automaticallyImplyLeading: false,

  title: Stack(
    alignment: Alignment.center,
    children: [
      // Centered Logo
      SizedBox(
        height: kToolbarHeight - 10,
        child: Image.asset(
          'assets/images/eclaroacademy.png',
          fit: BoxFit.contain,
        ),
      ),

      // Left-aligned text
      Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'Smart Inventory Application for School Uniform',
          style: TextStyle(
            fontSize: screenWidth < 350 ? 15 : 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF012060),
          ),
        ),
      ),
    ],
  ),
),

      body: Container(
        width: double.infinity,
        height: double.infinity,
         decoration: const BoxDecoration(
    color: Color(0xFF98cb0e), // your single background color
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
                  ElevatedButton.icon(
                    icon: const Icon(Icons.login, color: Colors.white),
                    label: const Text(
                      'Sign in with Google',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF012060),
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
                ],
              ),
            ),
          ),
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
