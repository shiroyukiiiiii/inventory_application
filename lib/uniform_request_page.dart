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
    setState(() { _isSubmitting = true; _message = null; });
    try {
      await FirebaseFirestore.instance.collection('uniform_requests').add({
        'userId': widget.user.uid,
        'userName': widget.user.displayName ?? '',
        'gender': _gender,
        'course': _course,
        'size': _size,
        'timestamp': FieldValue.serverTimestamp(),
      });
      setState(() { _message = 'Request submitted!'; });
    } catch (e) {
      setState(() { _message = 'Error: $e'; });
    } finally {
      setState(() { _isSubmitting = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Request Uniform')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Gender'),
                validator: (v) => v == null || v.isEmpty ? 'Enter gender' : null,
                onSaved: (v) => _gender = v!,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Course'),
                validator: (v) => v == null || v.isEmpty ? 'Enter course' : null,
                onSaved: (v) => _course = v!,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Size'),
                validator: (v) => v == null || v.isEmpty ? 'Enter size' : null,
                onSaved: (v) => _size = v!,
              ),
              const SizedBox(height: 20),
              if (_message != null)
                Text(_message!, style: TextStyle(color: _message == 'Request submitted!' ? Colors.green : Colors.red)),
              const SizedBox(height: 10),
              _isSubmitting
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _submitRequest,
                      child: const Text('Submit Request'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
