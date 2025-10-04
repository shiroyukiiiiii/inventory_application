import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/qr_service.dart';
import 'services/email_service.dart';

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
  String _gender = '';
  String _course = '';
  String _size = '';
  String _studentId = '';
  String _fullName = '';
  late String _email;
  late TextEditingController _emailController;
  bool _isSubmitting = false;
  String? _message;
  bool _showQRCode = false;

  @override
  void initState() {
  super.initState();
  _gender = widget.initialGender ?? '';
  _course = widget.initialCourse ?? '';
  _email = widget.user.email ?? '';
  _emailController = TextEditingController(text: _email);
  }

  void _generateQRPreview() {
    if (_studentId.isNotEmpty) {
      setState(() => _showQRCode = true);
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
      // ✅ Generate QR code bytes first
      final qrCodeBytes = await QRService.generateQRCodeBytes(_studentId);
      final qrBase64 = base64Encode(qrCodeBytes);

      // ✅ Save to Firestore (with QR code string)
      await FirebaseFirestore.instance.collection('uniform_requests').add({
        'userId': widget.user.uid,
        'userName': widget.user.displayName ?? '',
        'fullName': _fullName,
        'email': _email,
        'gender': _gender,
        'course': _course,
        'size': _size,
        'studentId': _studentId,
        'qrCode': qrBase64, // 👈 Store QR code here
        'timestamp': FieldValue.serverTimestamp(),
      });

      // ✅ Send Email (still optional)
      final emailSent = await EmailService.sendUniformRequestEmail(
        studentNumber: _studentId,
        studentName: _fullName.isNotEmpty ? _fullName : (widget.user.displayName ?? 'Unknown'),
        gender: _gender,
        course: _course,
        size: _size,
        qrCodeBytes: qrCodeBytes,
        toEmail: _email.isNotEmpty ? _email : (widget.user.email ?? ''),
      );

      setState(() {
        if (emailSent) {
          _message =
              'Request submitted, QR code saved to Firestore, and email sent!';
        } else {
          _message = 'Request submitted and QR code saved (email failed).';
        }
      });

      _formKey.currentState?.reset();
      _showQRCode = false;
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
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Full Name
              TextFormField(
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: (value) => value == null || value.isEmpty ? 'Enter your full name' : null,
                onSaved: (value) => _fullName = value ?? '',
                onChanged: (value) {
                  setState(() {
                    _fullName = value;
                  });
                },
              ),
              const SizedBox(height: 10),
              // Email (auto-filled and read-only)
              TextFormField(
                decoration: const InputDecoration(labelText: 'Email'),
                controller: _emailController,
                readOnly: true,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Email not found';
                  final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+\u0000?');
                  if (!emailRegex.hasMatch(value)) return 'Enter a valid email';
                  return null;
                },
                onSaved: (value) => _email = value ?? '',
              ),

              const SizedBox(height: 10),
              // Student ID
              TextFormField(
                decoration: const InputDecoration(labelText: 'Student Number'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Enter Student Number' : null,
                onSaved: (value) => _studentId = value ?? '',
                onChanged: (value) {
                  setState(() {
                    _studentId = value;
                    _showQRCode = false;
                  });
                },
              ),

              if (_studentId.isNotEmpty) ...[
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: _generateQRPreview,
                  icon: const Icon(Icons.qr_code),
                  label: const Text('Preview QR Code'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],

              if (_showQRCode && _studentId.isNotEmpty) ...[
                const SizedBox(height: 20),
                _buildQRPreview(),
              ],

              // Course Dropdown
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _course.isNotEmpty ? _course : null,
                decoration: const InputDecoration(labelText: 'Course'),
                items: const [
                  DropdownMenuItem(value: 'BSCS', child: Text('BSCS')),
                  DropdownMenuItem(value: 'ABCOM', child: Text('ABCOM')),
                  DropdownMenuItem(value: 'BSCRIM', child: Text('BSCRIM')),
                ],
                validator: (value) =>
                    value == null || value.isEmpty ? 'Select course' : null,
                onChanged: (value) {
                  setState(() {
                    _course = value ?? '';
                    _gender = '';
                    _size = '';
                  });
                },
                onSaved: (value) => _course = value ?? '',
              ),

              // Gender Dropdown
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _gender.isNotEmpty ? _gender : null,
                decoration: const InputDecoration(labelText: 'Gender'),
                items: const [
                  DropdownMenuItem(value: 'Male', child: Text('Male')),
                  DropdownMenuItem(value: 'Female', child: Text('Female')),
                ],
                validator: (value) =>
                    value == null || value.isEmpty ? 'Select gender' : null,
                onChanged: (value) {
                  setState(() {
                    _gender = value ?? '';
                    _size = '';
                  });
                },
                onSaved: (value) => _gender = value ?? '',
              ),

              const SizedBox(height: 20),

              // Inventory Sizes
              if (_course.isNotEmpty && _gender.isNotEmpty)
                _buildSizeInventory()
              else if (_course.isNotEmpty && _gender.isEmpty)
                _buildGenderReminder(),

              const SizedBox(height: 20),

              // Submit Button
              _isSubmitting
                  ? const Center(child: CircularProgressIndicator())
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

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Widget _buildQRPreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          const Text(
            'QR Code Preview',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          QRService.createQRCodeWidget(_studentId, size: 150),
          const SizedBox(height: 10),
          Text(
            'Student Number: $_studentId',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildSizeInventory() {
    return StreamBuilder<QuerySnapshot>(
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
          return const Text('No inventory data found for selected gender/course.');
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
            const Text(
              'Select Size:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
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
                secondary:
                    qty == 0 ? const Icon(Icons.block, color: Colors.red) : null,
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildGenderReminder() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: const Text(
        'Please select your gender to see available uniform sizes.',
        style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w500),
      ),
    );
  }
}
