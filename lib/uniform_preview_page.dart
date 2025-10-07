import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'uniform_request_page.dart';

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
    // Map female course images
    final Map<String, String> femaleImages = {
      'BSCRIM': 'assets/images/femalecrim.png',
      'ABCOM':
          'assets/images/femaleabbs.png', // Assuming abbs is the female abcom uniform
      'BSCS': 'assets/images/femaleabbs.png', // Optional
    };

    // Determine the image to display
    String uniformImage;
    if (gender == 'Male') {
      uniformImage = course == 'BSCRIM'
          ? 'assets/images/malecrim.png'
          : 'assets/images/maleabbs.png';
    } else {
      uniformImage =
          femaleImages[course] ?? 'assets/images/female_placeholder.png';
    }

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
            Icon(
              gender == 'Male' ? Icons.male : Icons.female,
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            Text(
              '$gender Uniform',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 20,
              ),
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
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
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
                    // Uniform Image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        uniformImage,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 25),

                    // Uniform title
                    Text(
                      '$gender Uniform for $course',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F1F1F),
                      ),
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'Preview your uniform and view details before submitting a request.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF555555),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Gradient Request Button
                    Container(
                      width: double.infinity,
                      height: 55,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF3A9D23), Color(0xFF00B4FF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: ElevatedButton(
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
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text(
                          'Request Uniform',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
}
