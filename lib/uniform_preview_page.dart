import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UniformPreviewPage extends StatefulWidget {
  final User? user;
  final String? initialGender;
  final String? initialCourse;

  const UniformPreviewPage({
    super.key,
    this.user,
    this.initialGender,
    this.initialCourse,
  });

  @override
  State<UniformPreviewPage> createState() => _UniformPreviewPageState();
}

class _UniformPreviewPageState extends State<UniformPreviewPage> {
  late TextEditingController nameController;
  late TextEditingController courseController;
  late String gender;

  @override
  void initState() {
    super.initState();

    // Initialize controllers with initial values
    nameController = TextEditingController(
      text: widget.user?.displayName ?? '',
    );

    courseController = TextEditingController(
      text: widget.initialCourse ?? '',
    );

    gender = widget.initialGender ?? 'Male';
  }

  @override
  void dispose() {
    nameController.dispose();
    courseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Uniform Preview'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: courseController,
              decoration: const InputDecoration(
                labelText: 'Course',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Gender: '),
                DropdownButton<String>(
                  value: gender,
                  items: const [
                    DropdownMenuItem(
                      value: 'Male',
                      child: Text('Male'),
                    ),
                    DropdownMenuItem(
                      value: 'Female',
                      child: Text('Female'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        gender = value;
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 32),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  // Example: Show a dialog preview
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Preview'),
                      content: Text(
                        'Name: ${nameController.text}\n'
                        'Course: ${courseController.text}\n'
                        'Gender: $gender',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text('Preview'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
