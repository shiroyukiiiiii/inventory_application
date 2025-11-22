import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class AdminQrConfirmationPage extends StatefulWidget {
  const AdminQrConfirmationPage({super.key});

  @override
  State<AdminQrConfirmationPage> createState() =>
      _AdminQrConfirmationPageState();
}

class _AdminQrConfirmationPageState extends State<AdminQrConfirmationPage> {
  bool _isProcessing = false;
  String? _lastScannedValue;
  bool _detected = false;

  final TextEditingController _manualController = TextEditingController();

  /// ✅ Handles both QR scan and manual input
  Future<void> _handleScan(String? qrData, {String method = "qr"}) async {
    setState(() {
      _lastScannedValue = qrData;
      _detected = qrData != null && qrData.trim().isNotEmpty;
      _isProcessing = true;
    });

    if (qrData != null && qrData.trim().isNotEmpty) {
      try {
        // ✅ Search Firestore by qrData (studentId + orderId)
        final query = await FirebaseFirestore.instance
            .collection('uniform_requests')
            .where('qrData', isEqualTo: qrData.trim())
            .limit(1)
            .get();

        String statusMessage;
        Color statusColor = Colors.red;

        if (query.docs.isNotEmpty) {
          final doc = query.docs.first;
          final data = doc.data();
          final studentNumber = data['studentId'] ?? '(unknown)';
          final orderId = data['orderId'] ?? '(no order id)';

          // get current user (admin) info
          final user = FirebaseAuth.instance.currentUser;
          final confirmer = user?.displayName ?? user?.email ?? 'Admin';

          if (data['status'] == 'Completed') {
            statusMessage =
                "ℹ️ Request for $studentNumber (Order ID: $orderId) is already completed.";
            statusColor = Colors.blue;
          } else {
            // mark completed and record confirmer + server timestamp
            await doc.reference.update({
              'status': 'Completed',
              'completedAt': FieldValue.serverTimestamp(),
              'confirmedBy': confirmer,
            });

            statusMessage =
                "✅ Request for $studentNumber (Order ID: $orderId) marked as completed by $confirmer!";
            statusColor = Colors.green;
          }
        } else {
          statusMessage = "❌ No request found for scanned QR data.";
          statusColor = Colors.red;
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(statusMessage),
              backgroundColor: statusColor,
              duration: const Duration(seconds: 3),
            ),
          );

          // ✅ Automatically close after a short delay
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) Navigator.pop(context);
          });
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("⚠️ Error scanning QR: $e"),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }

    setState(() => _isProcessing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'QR Confirmation',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Color(0xFF012060),
              ),
            ),
            SizedBox(
              height: kToolbarHeight - 10,
              child: Image.asset(
                'assets/images/eclaroacademy.png',
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // QR Scanner Section
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                MobileScanner(
                  onDetect: (capture) async {
                    if (_isProcessing) return;
                    for (final barcode in capture.barcodes) {
                      final String? scannedValue = barcode.rawValue;
                      _handleScan(scannedValue, method: "qr");
                      break;
                    }
                  },
                ),
                // ✅ Debug Overlay
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    color: Colors.black.withOpacity(0.7),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Debug Overlay',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Last scanned: ${_lastScannedValue ?? "(none)"}',
                          style: const TextStyle(color: Colors.white),
                        ),
                        Text(
                          'Detected: ${_detected ? "Yes" : "No"}',
                          style: const TextStyle(color: Colors.white),
                        ),
                        Text(
                          'Processing: ${_isProcessing ? "Yes" : "No"}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Manual Entry Section
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    "Manual QR Data Entry",
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _manualController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: "Enter full QR data (studentId-orderId)",
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _isProcessing
                        ? null
                        : () => _handleScan(
                              _manualController.text.trim(),
                              method: "manual",
                            ),
                    icon: const Icon(Icons.check),
                    label: const Text("Confirm Request"),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
