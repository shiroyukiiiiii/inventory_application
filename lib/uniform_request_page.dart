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
  final String _status = 'Pending';
  String _fullName = '';
  late String _email;
  late TextEditingController _emailController;
  late TextEditingController _orderQuantityController;
  late TextEditingController _fullNameController;
  late TextEditingController _studentIdController;

  int _orderQuantity = 1;
  bool _isSubmitting = false;
  String? _message;
  bool _showQRCode = false;
  bool _agreedToPrivacy = false;


  @override
  void initState() {
    super.initState();
    _gender = widget.initialGender ?? '';
    _course = widget.initialCourse ?? '';
    _email = widget.user.email ?? '';
    _emailController = TextEditingController(text: _email);
    _orderQuantityController = TextEditingController(text: '1');
    _fullNameController = TextEditingController();
    _studentIdController = TextEditingController();
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

      _orderQuantity = int.tryParse(_orderQuantityController.text) ?? 1;

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
        'status': _status,
        'orderQuantity': _orderQuantity,
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
        orderQuantity: _orderQuantity.toString(),
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
        backgroundColor: Color(0xFF012060),
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
                              MaterialPageRoute(
                                  builder: (context) => const SignInPage()),
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
                Icon(Icons.checkroom, color: Color(0xFF012060), size: 50),
                const SizedBox(height: 10),
                const Text(
                  'Uniform Request Form',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff012060),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),

          // 🔒 FIRST NAME
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'First Name',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty)
                return 'Enter your first name';
              final nameRegExp = RegExp(r'^[A-Za-z\s]+$');
              if (!nameRegExp.hasMatch(value)) {
                return 'First name must only contain letters';
              }
              return null;
            },
            onSaved: (value) => _fullName =
                '${value ?? ''} ${_fullName.split(' ').length > 1 ? _fullName.split(' ')[1] : ''}'
                    .trim(),
            onChanged: (value) {
              // Temporarily store first name in _fullName before last name is added
              _fullName = value;
            },
          ),

          const SizedBox(height: 15),

// 🔒 LAST NAME
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Last Name',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Enter your last name';
              final nameRegExp = RegExp(r'^[A-Za-z\s]+$');
              if (!nameRegExp.hasMatch(value)) {
                return 'Last name must only contain letters';
              }
              return null;
            },
            onSaved: (value) {
              _fullName = '${_fullName.trim()} ${value ?? ''}'.trim();
            },
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
            controller: _studentIdController,
            decoration: const InputDecoration(
              labelText: 'Student Number',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Enter Student Number';
              }

              // ✅ Allow only 4 digits, a dash, then 4 digits (e.g. 2022-1234)
              final pattern = RegExp(r'^\d{4}-\d{4}$');

              if (!pattern.hasMatch(value)) {
                return 'Invalid format. Use 4 digits, dash, then 4 digits (e.g. 2022-1234)';
              }

              // ✅ Optional: Check year validity
              final enteredYear = int.tryParse(value.substring(0, 4));
              final currentYear = DateTime.now().year;
              if (enteredYear == null || enteredYear > currentYear) {
                return 'Invalid or future year in student number';
              }

              return null;
            },
            onSaved: (value) => _studentId = value ?? '',
            onChanged: (value) {
              _studentId = value;
            },
          ),
          const SizedBox(height: 10),

          if (_studentId.isNotEmpty)
            ElevatedButton.icon(
              onPressed: _generateQRPreview,
              icon: const Icon(Icons.qr_code),
              label: const Text('Preview QR Code'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF98CB0E),
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

          CheckboxListTile(
            title: const Text(
              'I agree to the collection and processing of my personal data in accordance with the Data Privacy Act of 2012. My information will be used only for uniform request purposes.',
              style: TextStyle(fontSize: 13),
            ),
            value: _agreedToPrivacy,
            onChanged: (bool? value) {
              setState(() {
                _agreedToPrivacy = value ?? false;
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
          ),



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
          // ✅ Prevent submission unless the user agrees
          onPressed: _agreedToPrivacy
              ? _submitRequest
              : () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Please agree to the Data Privacy statement before submitting.',
                      ),
                      backgroundColor: Colors.redAccent,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF012060),
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
                    backgroundColor: Color(0xFF98CB0E),
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
                border: Border.all(color: Color(0xff012060)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Stock Available:',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Color(0xff012060)),
                  ),
                  Text(
                    '$totalStock pcs',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Color(0xff012060)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Select Size:' '\nNOTE: Price is 1000 PHP per set',
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
                  onChanged: (value) {
                    if (qty > 0) {
                      setState(() => _size = value ?? '');
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'No stock available for $size at the moment.'),
                          backgroundColor: Colors.redAccent,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  activeColor: Colors.teal,
                  secondary: qty == 0
                      ? const Icon(Icons.block, color: Colors.redAccent)
                      : const Icon(Icons.check_circle, color: Colors.teal),
                ),
              );
            }),

            const SizedBox(height: 15),

// Quantity input field
            TextFormField(
              controller: _orderQuantityController,
              decoration: const InputDecoration(
                labelText: 'Order Quantity',
                prefixIcon: Icon(Icons.shopping_cart_outlined),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Enter order quantity';
                }
                final qty = int.tryParse(value);
                if (qty == null || qty <= 0) {
                  return 'Enter a valid number (1 or more)';
                }
                return null;
              },
              onSaved: (value) =>
                  _orderQuantity = int.tryParse(value ?? '1') ?? 1,
            ),
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
    _orderQuantityController.dispose();

    _fullNameController.dispose();
    _studentIdController.dispose();
    super.dispose();
  }
}
