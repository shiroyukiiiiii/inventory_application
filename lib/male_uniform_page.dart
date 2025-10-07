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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.male, color: Colors.white),
            const SizedBox(width: 10),
            const Text(
              'Male Uniform',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 20),
            ),
            const SizedBox(width: 10),
            CircleAvatar(
              backgroundImage: NetworkImage(user.photoURL ?? ''),
              radius: 18,
              backgroundColor: Colors.white24,
            ),
            const SizedBox(width: 5),
            Text(
              user.displayName ?? '',
              style: const TextStyle(fontSize: 18, color: Colors.white),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF3A9D23), Color(0xFF00B4FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 35, vertical: 40),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.97),
                  borderRadius: BorderRadius.circular(35),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top banner
                    ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.asset(
                        'assets/images/eclaroacademy.png',
                        width: 160,
                        height: 50,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 25),
                    const Text(
                      'Select Your Course',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 35),

                    // Courses Wrap (BSCS centered)
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 25,
                      runSpacing: 25,
                      children: [
                        _buildCourseItem(context, 'BSCRIM', Colors.green, user),
                        _buildCourseItem(context, 'ABCOM', Colors.blue, user),
                        // Center the last item
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildCourseItem(
                                context, 'BSCS', Colors.teal, user),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCourseItem(
      BuildContext context, String course, Color color, User user) {
    return SizedBox(
      width: 160,
      child: Column(
        children: [
          // Image container with shadow
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                course == 'BSCRIM'
                    ? 'assets/images/malecrim.png'
                    : 'assets/images/maleabbs.png',
                fit: BoxFit.contain,
                width: double.infinity,
                height: 160,
              ),
            ),
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 6,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UniformPreviewPage(
                      gender: 'Male',
                      course: course,
                      user: user,
                    ),
                  ),
                );
              },
              child: Text(
                course,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
