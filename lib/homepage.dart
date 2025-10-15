import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main.dart';
import 'student_manage_requests_page.dart';
import 'select_sex_page.dart';

class HomePage extends StatelessWidget {
  final User user;

  const HomePage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 800;
    final isTablet = screenWidth > 500 && screenWidth <= 800;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Row(
          children: [
            const Icon(Icons.home_outlined, color: Colors.white),
            const SizedBox(width: 10),
            const Text(
              'Home Page',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: Colors.white,
              ),
            ),
            const Spacer(),
            CircleAvatar(
              backgroundImage: NetworkImage(user.photoURL ?? ''),
              radius: 18,
              backgroundColor: Colors.white24,
            ),
            const SizedBox(width: 8),
            Text(
              user.displayName ?? '',
              style: const TextStyle(fontSize: 16, color: Colors.white),
            ),
          ],
        ),
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4A90E2), Color(0xFF50E3C2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop
                    ? 200
                    : isTablet
                        ? 80
                        : 25,
                vertical: isDesktop ? 60 : 40,
              ),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(isDesktop ? 40 : 20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 🔹 Logo (responsive)
                    Image.asset(
                      'assets/images/eclaroacademy.png',
                      width: screenWidth * 0.5, // scales automatically
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 15),
                    Text(
                      'Welcome to SIASU!',
                      style: TextStyle(
                        fontSize: isDesktop ? 28 : 22,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'An inventory management system for school uniforms of college students.',
                      style: TextStyle(
                        fontSize: isDesktop ? 16 : 13,
                        color: Colors.black54,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 25),
                    const Text(
                      'Please select your course:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF4A90E2),
                      ),
                    ),
                    const SizedBox(height: 25),

                    // 📚 Course Sections
                    _buildCourseSection(
                      context,
                      user,
                      'BSCRIM',
                      const Color(0xFF4CAF50),
                      'assets/images/crim.png',
                      screenWidth,
                    ),
                    const SizedBox(height: 20),
                    _buildCourseSection(
                      context,
                      user,
                      'ABCOM',
                      const Color(0xFF42A5F5),
                      'assets/images/abbs.png',
                      screenWidth,
                    ),
                    const SizedBox(height: 20),
                    _buildCourseSection(
                      context,
                      user,
                      'BSCS',
                      const Color(0xFF26C6DA),
                      'assets/images/abbs.png',
                      screenWidth,
                    ),
                    const SizedBox(height: 30),

                    // 🧾 Manage Requests Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                              color: Color(0xFF4A90E2), width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        icon: const Icon(Icons.request_page_outlined,
                            color: Color(0xFF4A90E2)),
                        label: const Text(
                          'Manage My Requests',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF4A90E2),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  StudentManageRequestsPage(user: user),
                            ),
                          );
                        },
                      ),
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

  // 📦 Each Course Section (Responsive Design)
  Widget _buildCourseSection(BuildContext context, User user, String course,
      Color color, String imagePath, double screenWidth) {
    return Column(
      children: [
        Image.asset(
          imagePath,
          height: screenWidth < 400 ? 80 : 120,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              padding: EdgeInsets.symmetric(
                  horizontal: 30, vertical: screenWidth < 400 ? 12 : 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      SelectSexPage(user: user, course: course),
                ),
              );
            },
            child: Text(
              course,
              style: TextStyle(
                fontSize: screenWidth < 400 ? 16 : 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
