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
      appBar: AppBar(title: const Text('Web Uniform Request')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      decoration:
                          const InputDecoration(labelText: 'Student Number'),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Enter Student Number'
                          : null,
                      onSaved: (value) => _studentId = value ?? '',
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: _gender.isNotEmpty ? _gender : null,
                      decoration: const InputDecoration(labelText: 'Gender'),
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
                    DropdownButtonFormField<String>(
                      initialValue: _course.isNotEmpty ? _course : null,
                      decoration: const InputDecoration(labelText: 'Course'),
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
                    // You can add size selection and inventory logic here if needed
                    TextFormField(
                      decoration: const InputDecoration(
                          labelText: 'Size (e.g. M, L, XL)'),
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Enter size' : null,
                      onSaved: (value) => _size = value ?? '',
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
                          color: _message == 'Request submitted!'
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
