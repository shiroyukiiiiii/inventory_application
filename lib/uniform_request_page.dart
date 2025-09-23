import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';     // ✅ Firestore
import 'package:firebase_auth/firebase_auth.dart';        // ✅ Firebase User

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

  // form values
  String _name = '';
  String _email = '';
  String _studentId = '';
  String _gender = '';
  String _course = '';
  String _size = '';

  bool _isSubmitting = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    // Pre-fill if coming from preview page
    _gender = widget.initialGender ?? '';
    _course = widget.initialCourse ?? '';
    _email  = widget.user.email ?? '';
    _name   = widget.user.displayName ?? '';
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() {
      _isSubmitting = true;
      _message = null;
    });

    try {
      await FirebaseFirestore.instance.collection('requests').add({
        'name': _name,
        'email': _email,
        'studentId': _studentId,
        'gender': _gender,
        'course': _course,
        'size': _size,
        'uid': widget.user.uid,
        'timestamp': FieldValue.serverTimestamp(),
      });
      setState(() => _message = 'Request submitted!');
    } catch (e) {
      setState(() => _message = 'Error: $e');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Request Uniform')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                initialValue: _name,
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: (v) => v == null || v.isEmpty
                    ? 'Enter your name'
                    : !RegExp(r'^[a-zA-Z\s]+$').hasMatch(v)
                        ? 'Letters and spaces only'
                        : null,
                onSaved: (v) => _name = v!.trim(),
              ),
              TextFormField(
                initialValue: _email,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (v) => v == null || v.isEmpty
                    ? 'Enter your email'
                    : !RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$').hasMatch(v)
                        ? 'Invalid email'
                        : null,
                onSaved: (v) => _email = v!.trim(),
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Student Number'),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty
                    ? 'Enter Student Number'
                    : !RegExp(r'^\d{8}$').hasMatch(v)
                        ? 'Must be 8 digits'
                        : null,
                onSaved: (v) => _studentId = v!.trim(),
              ),
              DropdownButtonFormField<String>(
                value: _gender.isNotEmpty ? _gender : null,
                decoration: const InputDecoration(labelText: 'Gender'),
                items: const [
                  DropdownMenuItem(value: 'Male', child: Text('Male')),
                  DropdownMenuItem(value: 'Female', child: Text('Female')),
                ],
                validator: (v) => v == null || v.isEmpty ? 'Select gender' : null,
                onChanged: (v) => setState(() => _gender = v ?? ''),
                onSaved: (v) => _gender = v ?? '',
              ),
              DropdownButtonFormField<String>(
                value: _course.isNotEmpty ? _course : null,
                decoration: const InputDecoration(labelText: 'Course'),
                items: const [
                  DropdownMenuItem(value: 'BSCS', child: Text('BSCS')),
                  DropdownMenuItem(value: 'ABCOM', child: Text('ABCOM')),
                  DropdownMenuItem(value: 'BSCRIM', child: Text('BSCRIM')),
                ],
                validator: (v) => v == null || v.isEmpty ? 'Select course' : null,
                onChanged: (v) => setState(() => _course = v ?? ''),
                onSaved: (v) => _course = v ?? '',
              ),
              const SizedBox(height: 16),

              // ✅ Dynamic inventory based on selected gender & course
              StreamBuilder<QuerySnapshot>(
                stream: (_gender.isNotEmpty && _course.isNotEmpty)
                    ? FirebaseFirestore.instance
                        .collection('uniforms')
                        .where('gender', isEqualTo: _gender)
                        .where('course', isEqualTo: _course)
                        .snapshots()
                    : const Stream.empty(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Text('No inventory for selected gender/course.');
                  }

                  final Map<String, int> sizeInventory = {};
                  for (var doc in snapshot.data!.docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    sizeInventory[data['size']] = data['quantity'] ?? 0;
                  }

                  final sizes = ['XS', 'S', 'M', 'L', 'XL', 'XXL'];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Select Size:', style: TextStyle(fontWeight: FontWeight.bold)),
                      ...sizes.map((size) {
                        final qty = sizeInventory[size] ?? 0;
                        return RadioListTile<String>(
                          title: Text('$size  •  Available: $qty'),
                          value: size,
                          groupValue: _size,
                          onChanged: qty > 0 ? (v) => setState(() => _size = v ?? '') : null,
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
                    color: _message == 'Request submitted!' ? Colors.green : Colors.red,
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

