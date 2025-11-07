import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  String _username = '';
  String _password = '';
  bool _isLoading = false;
  String? _error;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final query = await _firestore
          .collection('admins')
          .where('username', isEqualTo: _username.trim())
          .limit(1)
          .get();

      if (query.docs.isEmpty) throw Exception('Username not found');

      final email = query.docs.first['email'] as String;

      await _auth.signInWithEmailAndPassword(
        email: email,
        password: _password,
      );

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/admin-inventory');
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message ?? 'Login failed');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _goToRegistration() {
    Navigator.pushNamed(context, '/admin-register');
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;

    return Scaffold(
      backgroundColor: const Color(0xFFE6F5F2),
      body: SafeArea(
        child: Stack(
          children: [
            // 🔙 Back Button
            Positioned(
              top: 10,
              left: 10,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new,
                    color: Color(0xFF1A5F7A)),
                iconSize: 26,
                onPressed: () => Navigator.pop(context),
              ),
            ),

            // 🧩 Centered Login Form
            Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isDesktop ? 450 : 360,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 15,
                          spreadRadius: 2,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.admin_panel_settings_rounded,
                            size: 70,
                            color: Colors.green.shade700,
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            "ADMIN LOGIN",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A5F7A),
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 25),

                          // Username Field
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Username',
                              prefixIcon: const Icon(Icons.person_outline,
                                  color: Color(0xFF1A5F7A)),
                              filled: true,
                              fillColor: const Color(0xFFF5F9F8),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: const BorderSide(
                                    color: Color(0xFF1A5F7A), width: 1.5),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onChanged: (val) => _username = val,
                            validator: (val) => val == null || val.isEmpty
                                ? 'Enter username'
                                : null,
                          ),
                          const SizedBox(height: 15),

                          // Password Field
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline,
                                  color: Color(0xFF1A5F7A)),
                              filled: true,
                              fillColor: const Color(0xFFF5F9F8),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: const BorderSide(
                                    color: Color(0xFF1A5F7A), width: 1.5),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            obscureText: true,
                            onChanged: (val) => _password = val,
                            validator: (val) => val == null || val.isEmpty
                                ? 'Enter password'
                                : null,
                          ),
                          const SizedBox(height: 25),

                          if (_error != null)
                            Text(
                              _error!,
                              style: const TextStyle(
                                  color: Colors.red, fontSize: 14),
                              textAlign: TextAlign.center,
                            ),
                          const SizedBox(height: 10),

                          // Login Button
                          _isLoading
                              ? const CircularProgressIndicator()
                              : SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1A5F7A),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      elevation: 5,
                                    ),
                                    onPressed: _login,
                                    child: const Text(
                                      'Login',
                                      style: TextStyle(
                                          fontSize: 18, color: Colors.white),
                                    ),
                                  ),
                                ),
                          const SizedBox(height: 15),

                          // Register Button
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
