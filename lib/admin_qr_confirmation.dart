import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  /// Common handler for QR and manual input
  Future<void> _handleScan(String? studentNumber, {String method = "qr"}) async {
  setState(() {
    _lastScannedValue = studentNumber;
    _detected = studentNumber != null && studentNumber.trim().isNotEmpty;
    _isProcessing = true;
  });

  if (studentNumber != null && studentNumber.trim().isNotEmpty) {
    final query = await FirebaseFirestore.instance
        .collection('uniform_requests')
        .where('studentId', isEqualTo: studentNumber.trim())
        .limit(1)
        .get();

    String statusMessage;
    Color statusColor = Colors.red;

    if (query.docs.isNotEmpty) {
      final doc = query.docs.first;
      final data = doc.data();

      // ✅ Already completed
      if (data['status'] == 'Completed') {
        statusMessage =
            "ℹ️ Request for $studentNumber is already Completed";
        statusColor = Colors.blue;
      } else {
        // ✅ Extract course, size, gender
        final String? course = data['course'] as String?;
        final String? size = data['size'] as String?;
        final String? gender = data['gender'] as String?;

        if (course == null || size == null || gender == null) {
          statusMessage =
              "⚠️ Request data is incomplete for $studentNumber (missing course/size/gender)";
          statusColor = Colors.orange;
        } else {
          // 🔹 Find the uniform doc based on course + size + gender
          final inventoryQuery = await FirebaseFirestore.instance
              .collection('uniforms')
              .where('course', isEqualTo: course)
              .where('size', isEqualTo: size)
              .where('gender', isEqualTo: gender)
              .limit(1)
              .get();

          if (inventoryQuery.docs.isNotEmpty) {
            final inventoryDoc = inventoryQuery.docs.first;

            // ✅ Perform both updates atomically in a transaction
            try {
              await FirebaseFirestore.instance
                  .runTransaction((transaction) async {
                final snapshot = await transaction.get(inventoryDoc.reference);
                final int currentCount =
                    (snapshot['quantity'] ?? 0).toInt();

                if (currentCount <= 0) {
                  throw Exception(
                      'No stock left for $course ($size, $gender)');
                }

                // Deduct 1 from stock
                transaction.update(inventoryDoc.reference, {
                  'quantity': currentCount - 1,
                });

                // Mark request as completed
                transaction.update(doc.reference, {
                  'status': 'Completed',
                });
              });

              statusMessage =
                  "✅ Request for $studentNumber marked as Completed — 1 stock deducted for $course ($size, $gender)";
              statusColor = Colors.green;
            } catch (e) {
              statusMessage = "⚠️ Stock deduction failed: ${e.toString()}";
              statusColor = Colors.orange;
            }
          } else {
            statusMessage =
                "❌ No inventory found for $course ($size, $gender)";
            statusColor = Colors.red;
          }
        }
      }
    } else {
      statusMessage = "❌ No request found for $studentNumber";
      statusColor = Colors.red;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(statusMessage), backgroundColor: statusColor),
      );
      Navigator.pop(context); // ✅ Close page after processing
    }
  }

  setState(() => _isProcessing = false);
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("QR Confirmation")),
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
                      final String? studentNumber = barcode.rawValue;
                      _handleScan(studentNumber, method: "qr");
                      break;
                    }
                  },
                ),
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
                              fontWeight: FontWeight.bold),
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
                    "Manual Student ID Entry",
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _manualController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: "Enter student number",
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