import 'package:cloud_firestore/cloud_firestore.dart';

class Uniform {
  final String id;
  final String gender;
  final String course;
  final String size;
  final int quantity;
  final Timestamp? addedAt; // ✅ Added timestamp

  Uniform({
    required this.id,
    required this.gender,
    required this.course,
    required this.size,
    required this.quantity,
    this.addedAt,
  });

  factory Uniform.fromMap(Map<String, dynamic> data, String id) {
    return Uniform(
      id: id,
      gender: data['gender'] ?? '',
      course: data['course'] ?? '',
      size: data['size'] ?? '',
      quantity: data['quantity'] ?? 0,
      addedAt: data['addedAt'], // ✅ Load timestamp
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'gender': gender,
      'course': course,
      'size': size,
      'quantity': quantity,
      'addedAt': addedAt ?? Timestamp.now(), // ✅ Auto-fill if missing
    };
  }
}
