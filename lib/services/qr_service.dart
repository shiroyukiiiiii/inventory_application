import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:path_provider/path_provider.dart';

class QRService {
  /// Generates a QR code image from student number and saves it to a file
  static Future<File> generateQRCodeFile(String studentNumber) async {
    try {
      // Create QR painter
      final painter = QrPainter(
        data: studentNumber,
        version: QrVersions.auto,
        color: const Color(0xFF000000),
        emptyColor: const Color(0xFFFFFFFF),
        gapless: false,
      );

      // Create a picture recorder
      final picData = await painter.toImageData(200);
      final pngBytes = picData!.buffer.asUint8List();

      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/qr_code_$studentNumber.png');
      await file.writeAsBytes(pngBytes);

      return file;
    } catch (e) {
      throw Exception('Failed to generate QR code: $e');
    }
  }

  /// Generates QR code as bytes for email attachment
  static Future<Uint8List> generateQRCodeBytes(String studentNumber) async {
    try {
      // Create QR painter
      final painter = QrPainter(
        data: studentNumber,
        version: QrVersions.auto,
        color: const Color(0xFF000000),
        emptyColor: const Color(0xFFFFFFFF),
        gapless: false,
      );

      // Create a picture recorder
      final picData = await painter.toImageData(200);
      
      return picData!.buffer.asUint8List();
    } catch (e) {
      throw Exception('Failed to generate QR code bytes: $e');
    }
  }

  /// Creates a QR code widget for display
  static Widget createQRCodeWidget(String studentNumber, {double size = 200}) {
    return QrImageView(
      data: studentNumber,
      version: QrVersions.auto,
      size: size,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
    );
  }
}