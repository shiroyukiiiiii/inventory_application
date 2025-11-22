import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main.dart';
import 'uniform_preview_page.dart';

class SelectSexPage extends StatelessWidget {
  final User user;
  final String course;

  const SelectSexPage({super.key, required this.user, required this.course});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth > 800;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
  elevation: 0,
  backgroundColor: Colors.white,
  automaticallyImplyLeading: false,
  titleSpacing: 0,
  title: Row(
    children: [
      // LEFT SIDE: Back + Uniform Text
      IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF012060)),
        onPressed: () => Navigator.pop(context),
      ),

      Text(
        '$course Uniform',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xFF012060),
          fontSize: 20,
        ),
      ),

      const Spacer(), // pushes the logo to the center
      // CENTER LOGO
      Image.asset(
        'assets/images/eclaroacademy.png',
        width: isDesktop ? 160 : 130,
        height: isDesktop ? 55 : 40,
        fit: BoxFit.contain,
      ),
      const Spacer(), // balances left/right spacing

      // RIGHT SIDE: Profile
      CircleAvatar(
        backgroundImage: NetworkImage(user.photoURL ?? ''),
        radius: 18,
        backgroundColor: Colors.white24,
      ),
      const SizedBox(width: 5),
      Text(
        user.displayName ?? '',
        style: const TextStyle(fontSize: 18, color: Color(0xFF012060)),
      ),
    ],
  ),

  // LOGOUT BUTTON
  actions: [
    IconButton(
      icon: const Icon(Icons.logout, color: Color(0xFF012060)),
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
    color: Color(0xFF98CB0E)),
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
                width: isDesktop ? 500 : 320,
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
                      
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Select Your Sex',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Male Button
                    _buildSexButton(
                      context,
                      'Male',
                      Color(0xFF012060),
                      Icons.male,
                      user,
                      course,
                    ),
                    const SizedBox(height: 20),

                    // Female Button
                    _buildSexButton(
                      context,
                      'Female',
                      const Color.fromARGB(255, 204, 37, 25),
                      Icons.female,
                      user,
                      course,
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

  Widget _buildSexButton(BuildContext context, String sex, Color color,
      IconData icon, User user, String course) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        icon: Icon(icon, color: Colors.white),
        label: Text(
          sex,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UniformPreviewPage(
                gender: sex,
                course: course,
                user: user,
              ),
            ),
          );
        },
      ),
    );
  }
}
