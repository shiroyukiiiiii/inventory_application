import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UniformRequestPage extends StatefulWidget {
  final User user;
  const UniformRequestPage({super.key, required this.user});

  @override
  State<UniformRequestPage> createState() => _UniformRequestPageState();
}

class _UniformRequestPageState extends State<UniformRequestPage> {
  final _formKey = GlobalKey<FormState>();
  String _gender = '';
  String _course = '';
  String _size = '';
  String _studentId = '';
  bool _isSubmitting = false;
  String? _message;

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() {
      _isSubmitting = true;
      _message = null;
    });
    try {
      await FirebaseFirestore.instance.collection('uniform_requests').add({
        'userId': widget.user.uid,
        'userName': widget.user.displayName ?? '',
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
      appBar: AppBar(title: const Text('Request Uniform')),
      body: Center(
        child: Padding(
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
                  value: _gender.isNotEmpty ? _gender : null,
                  decoration: const InputDecoration(labelText: 'Gender'),
                  items: const [
                    DropdownMenuItem(value: 'Male', child: Text('Male')),
                    DropdownMenuItem(value: 'Female', child: Text('Female')),
                  ],
                  validator: (value) => value == null || value.isEmpty ? 'Select gender' : null,
                  onChanged: (value) => setState(() => _gender = value ?? ''),
                  onSaved: (value) => _gender = value ?? '',
                ),
                DropdownButtonFormField<String>(
                  value: _course.isNotEmpty ? _course : null,
                  decoration: const InputDecoration(labelText: 'Course'),
                  items: const [
                    DropdownMenuItem(value: 'BSCS', child: Text('BSCS')),
                    DropdownMenuItem(value: 'ABCOM', child: Text('ABCOM')),
                    DropdownMenuItem(value: 'BSCRIM', child: Text('BSCRIM')),
                  ],
                  validator: (value) => value == null || value.isEmpty ? 'Select course' : null,
                  onChanged: (value) => setState(() => _course = value ?? ''),
                  onSaved: (value) => _course = value ?? '',
                ),
                DropdownButtonFormField<String>(
                  value: _size.isNotEmpty ? _size : null,
                  decoration: const InputDecoration(labelText: 'Size'),
                  items: const [
                    DropdownMenuItem(value: 'XS', child: Text('XS')),
                    DropdownMenuItem(value: 'S', child: Text('S')),
                    DropdownMenuItem(value: 'M', child: Text('M')),
                    DropdownMenuItem(value: 'L', child: Text('L')),
                    DropdownMenuItem(value: 'XL', child: Text('XL')),
                    DropdownMenuItem(value: 'XXL', child: Text('XXL')),
                  ],
                  validator: (value) => value == null || value.isEmpty ? 'Select size' : null,
                  onChanged: (value) => setState(() => _size = value ?? ''),
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
        ),
      ),
    );
  }
}
