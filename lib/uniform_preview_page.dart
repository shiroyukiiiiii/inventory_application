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
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF012060)),
          onPressed: () => Navigator.pop(context),
        ),
        title: SizedBox(
          height: kToolbarHeight - 10,
          child: Image.asset(
            'assets/images/eclaroacademy.png',
            fit: BoxFit.contain,
          ),
        ),
        centerTitle: true,
        actions: [
          CircleAvatar(
            backgroundImage: NetworkImage(user.photoURL ?? ''),
            radius: 16,
            backgroundColor: Colors.white24,
          ),
          const SizedBox(width: 8),
          Text(
            user.displayName ?? '',
            style: const TextStyle(fontSize: 14, color: Color(0xFF012060)),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFF012060)),
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
    );
  }
}

