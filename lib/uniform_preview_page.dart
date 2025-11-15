import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'uniform_request_page.dart';
import 'main.dart';

class UniformPreviewPage extends StatelessWidget {
  final String gender;
  final String course;
  final User user;

  const UniformPreviewPage({
    super.key,
    required this.gender,
    required this.course,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Color(0xFF012060);
    final Color secondaryColor = Color(0xFF012060);
    final Color accentColor = Colors.greenAccent.shade100;

    return Scaffold(
      backgroundColor: Color(0xff98cb0e),
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 4,
        centerTitle: true,
        toolbarHeight: 140,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/eclaroacademy.png',
              height: 250,
              width: 250,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 12),
            
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),

        actions: [
  IconButton(
    icon: const Icon(Icons.logout, color: Colors.white),
    onPressed: () {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Confirm Logout'),
            content: const Text('Are you sure you want to exit?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  FirebaseAuth.instance.signOut().then((_) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const SignInPage()),
                      (Route<dynamic> route) => false,
                    );
                  });
                },
                child: const Text('Logout'),
              ),
            ],
          );
        },
      );
    },
  ),
],

      ),
      body: Center(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
      color: Color(0xFF98CB0E), // ✅ Solid green background
    ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: secondaryColor.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 70,
                  backgroundColor: Colors.white,
                  child: Icon(
                    gender == 'Male' ? Icons.male : Icons.female,
                    size: 90,
                    color: secondaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 25),
              Text(
                '$gender Uniform for $course',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 15),
              Text(
                    'NOTE: Prices for Each Uniform Set 1000 PHP\n(Includes Shirt, Pants/Skirt)',
                    style: TextStyle(fontSize: 16, color: Color(0xFF012060)),
                    textAlign: TextAlign.center, // ✅ correct parameter
                  ),

              const SizedBox(height: 40),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: secondaryColor,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  shadowColor: primaryColor.withOpacity(0.4),
                  elevation: 6,
                ),
                icon: const Icon(Icons.request_page, color: Colors.white),
                label: const Text(
                  'Request Uniform',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
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
      ),
    );
  }
}
