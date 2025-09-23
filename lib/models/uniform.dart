class Uniform {
  final String id;
  final String gender; // 'Male' or 'Female'
  final String course; // e.g., 'Crim', 'ABCOM', 'BSCS'
  final String size; // e.g., 'S', 'M', 'L', 'XL'
  final int quantity;

  Uniform({
    required this.id,
    required this.gender,
    required this.course,
    required this.size,
    required this.quantity,
  });

  // Convert a Uniform object into a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'gender': gender,
      'course': course,
      'size': size,
      'quantity': quantity,
    };
  }

  // Create a Uniform object from a Firestore document
  factory Uniform.fromMap(Map<String, dynamic> map, String documentId) {
    return Uniform(
      id: documentId,
      gender: map['gender'] ?? '',
      course: map['course'] ?? '',
      size: map['size'] ?? '',
      quantity: map['quantity'] ?? 0,
    );
  }
}
