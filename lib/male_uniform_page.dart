import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main.dart';
import 'uniform_preview_page.dart';

class MaleUniformPage extends StatelessWidget {
  final User user;

  const MaleUniformPage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth > 800;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        // restore leading/back button and keep actions
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
          Row(
            children: [
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
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 60 : 20,
                vertical: isDesktop ? 60 : 40,
              ),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 40 : 25,
                  vertical: isDesktop ? 40 : 30,
                ),
                width: isDesktop ? 500 : 320, // ✅ responsive white box
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.97),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.asset(
                        'assets/images/eclaroacademy.png',
                        width: isDesktop ? 160 : 130,
                        height: isDesktop ? 55 : 40,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Select Your Course',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // ✅ Courses with images (not cropped)
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: isDesktop ? 30 : 20,
                      runSpacing: 25,
                      children: [
                        _buildCourseItem(
                          context,
                          'BSCRIM',
                          Colors.green,
                          user,
                          'assets/images/malecrim.png',
                        ),
                        _buildCourseItem(
                          context,
                          'B.A COM',
                          Colors.blue,
                          user,
                          'assets/images/maleabbs.png',
                        ),
                        _buildCourseItem(
                          context,
                          'BSCS',
                          Colors.teal,
                          user,
                          'assets/images/maleabbs.png',
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

  Widget _buildCourseItem(BuildContext context, String course, Color color,
      User user, String imagePath) {
    return SizedBox(
      width: 150, // ✅ adjusted for better desktop/mobile fit
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300, width: 1),
              color: Colors.white,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                imagePath,
                width: 120,
                height: 110,
                fit: BoxFit.contain, // ✅ no cropping
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 5,
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
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
