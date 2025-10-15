import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/qr_service.dart';
import 'services/email_service.dart';
import 'package:uuid/uuid.dart';
import 'main.dart';

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
    final tempOrderId = 'PREVIEW'; // or generate a temporary fake one
    final qrData = '$_studentId-$tempOrderId';

    setState(() {
      _showQRCode = true;
    });
    QRService.createQRCodeWidget(qrData, size: 150);
  }
}


  Future<void> _submitRequest() async {
  if (!_formKey.currentState!.validate()) return;
  _formKey.currentState!.save();

  // ✅ REQUIRED SIZE CHECK
  if (_size.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please select a uniform size before submitting.'),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
    return;
  }

  setState(() {
    _isSubmitting = true;
    _message = null;
  });

  try {
    final orderId = const Uuid().v4(); // Unique order ID for each request
    final qrData = '$_studentId-$orderId'; // ✅ Combine studentId + orderId
    final qrCodeBytes = await QRService.generateQRCodeBytes(qrData);
    final qrBase64 = base64Encode(qrCodeBytes);

    await FirebaseFirestore.instance.collection('uniform_requests').add({
      'orderId': orderId, // ✅ new unique order ID
      'userId': widget.user.uid,
      'userName': widget.user.displayName ?? '',
      'fullName': _fullName,
      'email': _email,
      'gender': _gender,
      'course': _course,
      'size': _size,
      'studentId': _studentId,
      'qrData': qrData, // ✅ updated to studentId + orderId
      'qrCode': qrBase64,
      'timestamp': FieldValue.serverTimestamp(),
});


    final emailSent = await EmailService.sendUniformRequestEmail(
      studentNumber: _studentId,
      studentName: _fullName.isNotEmpty
          ? _fullName
          : (widget.user.displayName ?? 'Unknown'),
      gender: _gender,
      course: _course,
      size: _size,
      qrCodeBytes: qrCodeBytes,
      toEmail: _email.isNotEmpty ? _email : (widget.user.email ?? ''),
    );

    setState(() {
      _message = emailSent
          ? 'Request submitted, QR code saved to Firestore, and email sent! Note: Kindly wait for the email approval before payment.'
          : 'Request submitted and QR code saved (email failed).';
    });

    _formKey.currentState?.reset();
    _showQRCode = false;
    _size = ''; // ✅ Reset size selection
  } catch (e) {
    setState(() => _message = 'Error: $e');
  } finally {
    setState(() => _isSubmitting = false);
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[50],
      appBar: AppBar(
        title: const Text('Request Uniform'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 2,

        actions: [
  IconButton(
    icon: const Icon(Icons.logout, color: Colors.white),
    onPressed: () {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Confirm Logout'),
            content: const Text('Are you sure you want to exit?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  FirebaseAuth.instance.signOut().then((_) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const SignInPage()),
                      (Route<dynamic> route) => false,
                    );
                  });
                },
                child: const Text('Logout'),
              ),
            ],
          );
        },
      );
    },
  ),
],

      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: _buildForm(),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                Icon(Icons.checkroom, color: Colors.teal, size: 80),
                const SizedBox(height: 10),
                const Text(
                  'Uniform Request Form',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),

          // 🔒 FULL NAME VALIDATION
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Full Name',
              prefixIcon: Icon(Icons.person_outline),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Enter your full name';
              final nameRegExp = RegExp(r'^[A-Za-z\s]+$');
              if (!nameRegExp.hasMatch(value)) {
                return 'Full name must only contain letters and spaces';
              }
              return null;
            },
            onSaved: (value) => _fullName = value ?? '',
            onChanged: (value) => setState(() => _fullName = value),
          ),

          const SizedBox(height: 15),

          // 🔒 EMAIL VALIDATION
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined),
              border: OutlineInputBorder(),
            ),
            controller: _emailController,
            readOnly: true,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Email not found';
              final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
              if (!emailRegex.hasMatch(value)) return 'Enter a valid email';
              return null;
            },
            onSaved: (value) => _email = value ?? '',
          ),

          const SizedBox(height: 15),

          // 🔒 STUDENT NUMBER VALIDATION
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Student Number',
              prefixIcon: Icon(Icons.badge_outlined),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Enter Student Number';
              final currentYear = DateTime.now().year;
              final pattern = RegExp(r'^(20\d{2})([-]?\d+)?$');
              final match = pattern.firstMatch(value);
              if (match == null) {
                return 'Invalid student number format. Use format like 2022-12345';
              }
              final enteredYear = int.tryParse(match.group(1) ?? '');
              if (enteredYear == null) return 'Invalid year in student number';
              if (enteredYear > currentYear) {
                return 'Year cannot be in the future';
              }
              return null;
            },
            onSaved: (value) => _studentId = value ?? '',
            onChanged: (value) {
              setState(() {
                _studentId = value;
                _showQRCode = false;
              });
            },
          ),

          const SizedBox(height: 10),

          if (_studentId.isNotEmpty)
            ElevatedButton.icon(
              onPressed: _generateQRPreview,
              icon: const Icon(Icons.qr_code),
              label: const Text('Preview QR Code'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 45),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),

          if (_showQRCode && _studentId.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildQRPreview(),
          ],

          const SizedBox(height: 20),
          // Course
          TextFormField(
            readOnly: true,
            initialValue: _course,
            decoration: const InputDecoration(
              labelText: 'Course',
              prefixIcon: Icon(Icons.school_outlined),
              border: OutlineInputBorder(),
            ),
            validator: (value) =>
                value == null || value.isEmpty ? 'Select course' : null,
          ),

          const SizedBox(height: 15),
          // Gender
          TextFormField(
            readOnly: true,
            initialValue: _gender,
            decoration: const InputDecoration(
              labelText: 'Sex',
              prefixIcon: Icon(Icons.people_alt_outlined),
              border: OutlineInputBorder(),
            ),
            validator: (value) =>
                value == null || value.isEmpty ? 'Select Sex' : null,
          ),

          const SizedBox(height: 20),

          if (_course.isNotEmpty && _gender.isNotEmpty)
            _buildSizeInventory()
          else if (_course.isNotEmpty && _gender.isEmpty)
            _buildGenderReminder(),

          const SizedBox(height: 25),

          _isSubmitting
              ? const Center(child: CircularProgressIndicator())
              : SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.send),
                    label: const Text(
                      'Submit Request',
                      style: TextStyle(fontSize: 16),
                    ),
                    onPressed: _submitRequest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
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
    );
  }

  Widget _buildQRPreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal),
      ),
      child: Column(
        children: [
          const Text(
            'QR Code Preview',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          QRService.createQRCodeWidget('$_studentId-PREVIEW', size: 150),
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
          return const Text(
            'No uniform inventory available for this course and Sex.',
            style: TextStyle(color: Colors.grey),
          );
        }

        final uniforms = snapshot.data!.docs;
        final Map<String, int> sizeInventory = {};

        for (var doc in uniforms) {
          final data = doc.data() as Map<String, dynamic>;
          final size = (data['size'] ?? '').toString();
          final quantity = (data['quantity'] ?? 0) as int;
          sizeInventory[size] = (sizeInventory[size] ?? 0) + quantity;
        }

        final sizes = ['XS', 'S', 'M', 'L', 'XL', 'XXL'];
        final totalStock = sizeInventory.values.fold<int>(0, (a, b) => a + b);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Size Chart Button (always visible for BSCS & ABCOM)
            if (_course == 'BSCS' || _course == 'ABCOM')
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Size Chart'),
                        content: Image.asset(
                          _gender == 'Female'
                              ? 'assets/images/femalesz.png'
                              : 'assets/images/malesz.png',
                          fit: BoxFit.contain,
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
                  icon: const Icon(Icons.info_outline),
                  label: const Text('Size Chart'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 45),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),

            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.teal.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Stock Available:',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.teal),
                  ),
                  Text(
                    '$totalStock pcs',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.blueAccent),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Select Size:''\nNOTE: Price is 1000 PHP per set',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...sizes.map((size) {
              final qty = sizeInventory[size] ?? 0;
              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 4),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                child: RadioListTile<String>(
                  title: Text(
                    '$size — Available: $qty',
                    style: TextStyle(
                      color: qty == 0 ? Colors.grey : Colors.black87,
                      fontWeight:
                          qty == 0 ? FontWeight.normal : FontWeight.w500,
                    ),
                  ),
                  value: size,
                  groupValue: _size,
                  onChanged: qty > 0
                      ? (value) => setState(() => _size = value ?? '')
                      : null,
                  activeColor: Colors.teal,
                  secondary: qty == 0
                      ? const Icon(Icons.block, color: Colors.redAccent)
                      : const Icon(Icons.check_circle, color: Colors.teal),
                ),
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

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}
