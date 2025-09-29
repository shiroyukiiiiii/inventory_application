import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/qr_service.dart';
import 'services/email_service.dart';

class UniformRequestPage extends StatefulWidget {
  final User user;
  final String? initialGender;
  final String? initialCourse;
  const UniformRequestPage({super.key, required this.user, this.initialGender, this.initialCourse});

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
  bool _showQRCode = false;

  @override
  void initState() {
    super.initState();
    _gender = widget.initialGender ?? '';
    _course = widget.initialCourse ?? '';
  }

  void _generateQRPreview() {
    if (_studentId.isNotEmpty) {
      setState(() {
        _showQRCode = true;
      });
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
      // Save to Firestore
      await FirebaseFirestore.instance.collection('uniform_requests').add({
        'userId': widget.user.uid,
        'userName': widget.user.displayName ?? '',
        'gender': _gender,
        'course': _course,
        'size': _size,
        'studentId': _studentId,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Generate QR code and send email
      try {
        // Generate QR code bytes
        final qrCodeBytes = await QRService.generateQRCodeBytes(_studentId);
        
        // Send email with QR code attachment
        final emailSent = await EmailService.sendUniformRequestEmail(
          studentNumber: _studentId,
          studentName: widget.user.displayName ?? 'Unknown',
          gender: _gender,
          course: _course,
          size: _size,
          qrCodeBytes: qrCodeBytes,
        );

        if (emailSent) {
          setState(() {
            _message = 'Request submitted and confirmation email sent with QR code!';
          });
        } else {
          setState(() {
            _message = 'Request submitted! (Email sending failed)';
          });
        }
      } catch (emailError) {
        print('Email error: $emailError');
        setState(() {
          _message = 'Request submitted! (Email sending failed: $emailError)';
        });
      }

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
                      decoration: const InputDecoration(labelText: 'Student Number'),
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Enter Student Number' : null,
                      onSaved: (value) => _studentId = value ?? '',
                      onChanged: (value) {
                        setState(() {
                          _studentId = value;
                          _showQRCode = false; // Reset QR code when student number changes
                        });
                      },
                    ),
                    if (_studentId.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
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
                      ),
                    ],
                    if (_showQRCode && _studentId.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'QR Code Preview',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            QRService.createQRCodeWidget(_studentId, size: 150),
                            const SizedBox(height: 10),
                            Text(
                              'Student Number: $_studentId',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    DropdownButtonFormField<String>(
                      initialValue: _course.isNotEmpty ? _course : null,
                      decoration: const InputDecoration(labelText: 'Course'),
                      items: const [
                        DropdownMenuItem(value: 'BSCS', child: Text('BSCS')),
                        DropdownMenuItem(value: 'ABCOM', child: Text('ABCOM')),
                        DropdownMenuItem(value: 'BSCRIM', child: Text('BSCRIM')),
                      ],
                      validator: (value) => value == null || value.isEmpty ? 'Select course' : null,
                      onChanged: (value) {
                        setState(() {
                          _course = value ?? '';
                          _gender = ''; // Reset gender when course changes
                          _size = ''; // Reset size when course changes
                        });
                      },
                      onSaved: (value) => _course = value ?? '',
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: _gender.isNotEmpty ? _gender : null,
                      decoration: const InputDecoration(labelText: 'Gender'),
                      items: const [
                        DropdownMenuItem(value: 'Male', child: Text('Male')),
                        DropdownMenuItem(value: 'Female', child: Text('Female')),
                      ],
                      validator: (value) => value == null || value.isEmpty ? 'Select gender' : null,
                      onChanged: (value) {
                        setState(() {
                          _gender = value ?? '';
                          _size = ''; // Reset size when gender changes
                        });
                      },
                      onSaved: (value) => _gender = value ?? '',
                    ),
                    // Show inventory only when both course and gender are selected
                    if (_course.isNotEmpty && _gender.isNotEmpty) ...[
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
                            return const Text('No inventory data found for selected gender/course.');
                          }
                        final uniformData = snapshot.data!.docs;
                        // Build a map of size to quantity
                        final Map<String, int> sizeInventory = {};
                        for (var doc in uniformData) {
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
                    ] else if (_course.isNotEmpty && _gender.isEmpty) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: const Text(
                          'Please select your gender to see available uniform sizes.',
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
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
