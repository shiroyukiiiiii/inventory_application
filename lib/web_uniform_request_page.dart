import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';

class WebUniformRequestPage extends StatefulWidget {
  const WebUniformRequestPage({super.key});

  @override
  State<WebUniformRequestPage> createState() => _WebUniformRequestPageState();
}

class _WebUniformRequestPageState extends State<WebUniformRequestPage> {
  final _formKey = GlobalKey<FormState>();
  String _gender = '';
  String _course = '';
  String _size = '';
  String _studentId = '';
  bool _isSubmitting = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() {
      _isSubmitting = true;
      _message = null;
    });
    try {
      await FirebaseFirestore.instance.collection('uniform_requests').add({
        'gender': _gender,
        'course': _course,
        'size': _size,
        'studentId': _studentId,
        'timestamp': FieldValue.serverTimestamp(),
      });
      setState(() {
        _message = 'Request submitted!';
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
      backgroundColor: const Color(0xFFE6F2FF), // light blue background
      appBar: AppBar(
        title: const Text('Uniform Request Form'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF3A9D23), Color(0xFF00B4FF)], // green to blue
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
              width: 600, // central fixed width for readability
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Uniform Request Form',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 30),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Student Number',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      style: const TextStyle(fontSize: 18),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Enter Student Number'
                          : null,
                      onSaved: (value) => _studentId = value ?? '',
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      value: _gender.isNotEmpty ? _gender : null,
                      decoration: InputDecoration(
                        labelText: 'Gender',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      style:
                          const TextStyle(fontSize: 18, color: Colors.black87),
                      items: const [
                        DropdownMenuItem(value: 'Male', child: Text('Male')),
                        DropdownMenuItem(
                            value: 'Female', child: Text('Female')),
                      ],
                      validator: (value) => value == null || value.isEmpty
                          ? 'Select gender'
                          : null,
                      onChanged: (value) =>
                          setState(() => _gender = value ?? ''),
                      onSaved: (value) => _gender = value ?? '',
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      value: _course.isNotEmpty ? _course : null,
                      decoration: InputDecoration(
                        labelText: 'Course',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      style:
                          const TextStyle(fontSize: 18, color: Colors.black87),
                      items: const [
                        DropdownMenuItem(value: 'BSCS', child: Text('BSCS')),
                        DropdownMenuItem(value: 'ABCOM', child: Text('ABCOM')),
                        DropdownMenuItem(
                            value: 'BSCRIM', child: Text('BSCRIM')),
                      ],
                      validator: (value) => value == null || value.isEmpty
                          ? 'Select course'
                          : null,
                      onChanged: (value) =>
                          setState(() => _course = value ?? ''),
                      onSaved: (value) => _course = value ?? '',
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Size (e.g. M, L, XL)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      style: const TextStyle(fontSize: 18),
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Enter size' : null,
                      onSaved: (value) => _size = value ?? '',
                    ),
                    const SizedBox(height: 30),
                    _isSubmitting
                        ? const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF3A9D23)),
                          )
                        : SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3A9D23),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                elevation: 5,
                              ),
                              onPressed: _submitRequest,
                              child: const Text(
                                'Submit Request',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                    if (_message != null) ...[
                      const SizedBox(height: 25),
                      Text(
                        _message!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _message == 'Request submitted!'
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                    ],
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
