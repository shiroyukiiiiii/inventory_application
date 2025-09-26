import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class UniformRequestPage extends StatefulWidget {
  final User user;
  final String? initialGender;
  final String? initialCourse;

  const UniformRequestPage({
    super.key,
    required this.user,
    this.initialGender,
    this.initialCourse,
  });

  @override
  State<UniformRequestPage> createState() => _UniformRequestPageState();
}

class _UniformRequestPageState extends State<UniformRequestPage> {
  final _formKey = GlobalKey<FormState>();
  late String _gender;
  late String _course;
  String _size = '';
  String _studentId = '';
  bool _isSubmitting = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _gender = widget.initialGender ?? '';
    _course = widget.initialCourse ?? '';
  }

  /// ✅ Sends email via EmailJS with course & size
  Future<void> _sendEmail({
    required String name,
    required String studentNumber,
    required String course,
    required String size,
  }) async {
    const serviceId = 'service_8hwyvbt';   // 👉 replace with your EmailJS service ID
    const templateId = 'template_nyx8quh'; // 👉 replace with your EmailJS template ID
    const userId = '_VxrLuVeFMOAXs46e';             // 👉 replace with your EmailJS public key

    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
    final response = await http.post(
      url,
      headers: {
        'origin': 'http://localhost', // required by EmailJS
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'service_id': serviceId,
        'template_id': templateId,
        'user_id': userId,
        'template_params': {
          'name': name,
          'student_number': studentNumber,
          'course': course, // ✅ new
          'size': size,     // ✅ new
          'time': DateTime.now().toString(),
          'message': 'Your request is being viewed for approval.',
        },
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Email failed: ${response.body}');
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() {
      _isSubmitting = true;
      _message = null;
    });

    try {
      // ✅ Save request to Firestore
      await FirebaseFirestore.instance.collection('uniform_requests').add({
        'userId': widget.user.uid,
        'userName': widget.user.displayName ?? '',
        'gender': _gender,
        'course': _course,
        'size': _size,
        'studentId': _studentId,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // ✅ Send Email Notification
      await _sendEmail(
        name: widget.user.displayName ?? 'Anonymous',
        studentNumber: _studentId,
        course: _course,
        size: _size,
      );

      setState(() {
        _message = 'Request submitted! An email notification has been sent.';
      });
      _formKey.currentState?.reset();
    } catch (e) {
      setState(() {
        _message = 'Error: $e';
      });
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Request Uniform')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Student Number'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Enter Student Number' : null,
                onSaved: (value) => _studentId = value ?? '',
              ),
              DropdownButtonFormField<String>(
                initialValue: _gender.isNotEmpty ? _gender : null,
                decoration: const InputDecoration(labelText: 'Gender'),
                items: const [
                  DropdownMenuItem(value: 'Male', child: Text('Male')),
                  DropdownMenuItem(value: 'Female', child: Text('Female')),
                ],
                validator: (value) =>
                    value == null || value.isEmpty ? 'Select gender' : null,
                onChanged: (value) => setState(() => _gender = value ?? ''),
                onSaved: (value) => _gender = value ?? '',
              ),
              DropdownButtonFormField<String>(
                initialValue: _course.isNotEmpty ? _course : null,
                decoration: const InputDecoration(labelText: 'Course'),
                items: const [
                  DropdownMenuItem(value: 'BSCS', child: Text('BSCS')),
                  DropdownMenuItem(value: 'ABCOM', child: Text('ABCOM')),
                  DropdownMenuItem(value: 'BSCRIM', child: Text('BSCRIM')),
                ],
                validator: (value) =>
                    value == null || value.isEmpty ? 'Select course' : null,
                onChanged: (value) => setState(() => _course = value ?? ''),
                onSaved: (value) => _course = value ?? '',
              ),
              const SizedBox(height: 20),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('uniforms')
                    .where('gender', isEqualTo: _gender)
                    .where('course', isEqualTo: _course)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Text(
                      'No inventory data found for selected gender/course.',
                    );
                  }
                  final uniformData = snapshot.data!.docs;
                  final Map<String, int> sizeInventory = {};
                  for (var doc in uniformData) {
                    final data = doc.data() as Map<String, dynamic>;
                    sizeInventory[data['size']] = data['quantity'] ?? 0;
                  }
                  final sizes = ['XS', 'S', 'M', 'L', 'XL', 'XXL'];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Select Size:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      ...sizes.map((size) {
                        final qty = sizeInventory[size] ?? 0;
                        return RadioListTile<String>(
                          title: Text('$size  •  Available: $qty'),
                          value: size,
                          groupValue: _size,
                          onChanged: qty > 0
                              ? (value) => setState(() => _size = value ?? '')
                              : null,
                          activeColor: Colors.blue,
                          secondary: qty == 0
                              ? const Icon(Icons.block, color: Colors.red)
                              : null,
                        );
                      }),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
              _isSubmitting
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _submitRequest,
                      child: const Text('Submit Request'),
                    ),
              if (_message != null) ...[
                const SizedBox(height: 20),
                Text(
                  _message!,
                  style: TextStyle(
                    color: _message!.startsWith('Request submitted')
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
