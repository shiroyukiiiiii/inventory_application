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
    final isPhone = screenWidth <= 500;

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
              backgroundImage:
                  user.photoURL != null && user.photoURL!.isNotEmpty
                      ? NetworkImage(user.photoURL!)
                      : null,
              radius: 18,
              backgroundColor: Colors.white24,
              child: user.photoURL == null || user.photoURL!.isEmpty
                  ? const Icon(Icons.person, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                user.displayName ?? '',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout', // ✅ Tooltip added here
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
                          Navigator.pop(context);
                          FirebaseAuth.instance.signOut().then((_) {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (context) => const SignInPage(),
                              ),
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
                        : 20,
                vertical: isDesktop ? 60 : 30,
              ),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(isDesktop ? 40 : 18),
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
                constraints: const BoxConstraints(maxWidth: 900),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 🔹 Smaller logo on mobile
                    Image.asset(
                      'assets/images/eclaroacademy.png',
                      width: isPhone
                          ? screenWidth * 0.35
                          : screenWidth * 0.22, // smaller for phones
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Welcome to SIASU!',
                      style: TextStyle(
                        fontSize: isDesktop
                            ? 28
                            : isTablet
                                ? 24
                                : 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF333333),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'An inventory management system for school uniforms of college students.',
                      style: TextStyle(
                        fontSize: isDesktop
                            ? 16
                            : isTablet
                                ? 14
                                : 12,
                        color: Colors.black54,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 25),
                    const Text(
                      'Please select your course:',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4A90E2),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // 📚 Responsive Courses Grid
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: isPhone ? 15 : 25,
                      runSpacing: isPhone ? 15 : 25,
                      children: [
                        _buildCourseButton(
                          context,
                          user,
                          'BSCRIM',
                          const Color(0xFF4CAF50),
                          'assets/images/crim.png',
                          screenWidth,
                          isPhone,
                        ),
                        _buildCourseButton(
                          context,
                          user,
                          'B.A COM',
                          const Color(0xFF42A5F5),
                          'assets/images/abbs.png',
                          screenWidth,
                          isPhone,
                        ),
                        _buildCourseButton(
                          context,
                          user,
                          'BSCS',
                          const Color(0xFF26C6DA),
                          'assets/images/abbs.png',
                          screenWidth,
                          isPhone,
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),

                    // 🧾 Manage Requests Button
                    SizedBox(
                      width: double.infinity,
                      height: isPhone ? 50 : 55,
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
                            fontSize: 18,
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

  // 🎓 Responsive Course Buttons
  Widget _buildCourseButton(BuildContext context, User user, String course,
      Color color, String imagePath, double screenWidth, bool isPhone) {
    return SizedBox(
      width: isPhone ? 140 : 140, // ⬅️ wider button for course
      height: isPhone ? 180 : 230, // ⬅️ taller to fit larger image
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
          elevation: 6,
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SelectSexPage(user: user, course: course),
            ),
          );
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // ✅ center content
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              flex: 7,
              child: Center(
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.contain,
                  width: isPhone ? 85 : 100, // ⬅️ larger image
                  height: isPhone ? 200 : 200,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              course,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isPhone ? 18 : 20, // ⬅️ larger text
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
