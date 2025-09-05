class Uniform {
  final String id;
  final String gender;
  final String course;
  final String size;
  final int quantity;

  Uniform({
    required this.id,
    required this.gender,
    required this.course,
    required this.size,
    required this.quantity,
  });

  factory Uniform.fromMap(Map<String, dynamic> data, String documentId) {
    return Uniform(
      id: documentId,
      gender: data['gender'] ?? '',
      course: data['course'] ?? '',
      size: data['size'] ?? '',
      quantity: data['quantity'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'gender': gender,
      'course': course,
      'size': size,
      'quantity': quantity,
    };
  }
}
