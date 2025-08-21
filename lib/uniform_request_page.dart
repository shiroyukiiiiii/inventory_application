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
                  decoration: const InputDecoration(labelText: 'Gender'),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Enter gender' : null,
                  onSaved: (value) => _gender = value ?? '',
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Course'),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Enter course' : null,
                  onSaved: (value) => _course = value ?? '',
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Size'),
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
        ),
      ),
    );
  }
}
