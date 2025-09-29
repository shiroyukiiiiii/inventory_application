import 'package:flutter/material.dart';
import 'services/qr_service.dart';

class QRTestPage extends StatefulWidget {
  const QRTestPage({super.key});

  @override
  State<QRTestPage> createState() => _QRTestPageState();
}

class _QRTestPageState extends State<QRTestPage> {
  final TextEditingController _studentNumberController = TextEditingController();
  bool _showQRCode = false;

  @override
  void dispose() {
    _studentNumberController.dispose();
    super.dispose();
  }

  void _generateQRCode() {
    if (_studentNumberController.text.isNotEmpty) {
      setState(() {
        _showQRCode = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Code Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Test QR Code Generation',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _studentNumberController,
              decoration: const InputDecoration(
                labelText: 'Enter Student Number',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _generateQRCode,
              icon: const Icon(Icons.qr_code),
              label: const Text('Generate QR Code'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 30),
            if (_showQRCode && _studentNumberController.text.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey.shade50,
                ),
                child: Column(
                  children: [
                    const Text(
                      'Generated QR Code',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    QRService.createQRCodeWidget(
                      _studentNumberController.text,
                      size: 200,
                    ),
                    const SizedBox(height: 15),
                    Text(
                      'Student Number: ${_studentNumberController.text}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'This QR code will be attached to the email when a uniform request is submitted.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How it works:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '1. Enter a student number above\n'
                    '2. Click "Generate QR Code" to see the preview\n'
                    '3. When submitting a uniform request, this QR code will be automatically generated and attached to the confirmation email',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
