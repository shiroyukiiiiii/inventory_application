import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_scanner/mobile_scanner.dart';


class AdminQrConfirmationPage extends StatefulWidget {
  const AdminQrConfirmationPage({super.key});

  @override
  State<AdminQrConfirmationPage> createState() => _AdminQrConfirmationPageState();
}

class _AdminQrConfirmationPageState extends State<AdminQrConfirmationPage> {
  bool _isProcessing = false;

  Future<void> _markAsCompleted(String requestId) async {
    try {
      await FirebaseFirestore.instance
          .collection('uniform_requests')
          .doc(requestId)
          .update({'status': 'completed'}); // ✅ use lowercase to match filters

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("✅ Request $requestId marked as completed")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Error: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan QR Code")),
      body: MobileScanner(
        onDetect: (capture) async {
          if (_isProcessing) return;
          setState(() => _isProcessing = true);

          for (final barcode in capture.barcodes) {
            final String? code = barcode.rawValue;
            if (code != null && code.trim().isNotEmpty) {
              await _markAsCompleted(code.trim());
              Navigator.pop(context); // ✅ exit after successful scan
              break;
            }
          }
        },
      ),
    );
  }
}
