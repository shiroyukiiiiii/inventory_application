import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:path_provider/path_provider.dart';

class QRService {
  static Future<File> generateQRCodeFile(String studentNumber) async {
    try {
      final cleanData = studentNumber.trim();
      final painter = QrPainter(
        data: cleanData,
        version: QrVersions.auto,
        eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square),
        dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square),
        color: const Color(0xFF000000),
        emptyColor: const Color(0xFFFFFFFF),
        gapless: false,
      );

      final picData = await painter.toImageData(600); // 🔼 higher resolution
      final pngBytes = picData!.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/qr_code_$cleanData.png');
      await file.writeAsBytes(pngBytes);

      return file;
    } catch (e) {
      throw Exception('Failed to generate QR code: $e');
    }
  }

  static Future<Uint8List> generateQRCodeBytes(String studentNumber) async {
    try {
      final cleanData = studentNumber.trim();
      final painter = QrPainter(
        data: cleanData,
        version: QrVersions.auto,
        color: const Color(0xFF000000),
        emptyColor: const Color(0xFFFFFFFF),
        gapless: false,
      );
      final picData = await painter.toImageData(600);
      return picData!.buffer.asUint8List();
    } catch (e) {
      throw Exception('Failed to generate QR code bytes: $e');
    }
  }

  static Widget createQRCodeWidget(String studentNumber, {double size = 220}) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(10),
      child: QrImageView(
        data: studentNumber.trim(),
        version: QrVersions.auto,
        size: size,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
    );
  }
}
