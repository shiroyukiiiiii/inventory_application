import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditUniformRequestPage extends StatefulWidget {
  final String requestId;
  final Map<String, dynamic> requestData;
  const EditUniformRequestPage({
    super.key,
    required this.requestId,
    required this.requestData,
  });

  @override
  State<EditUniformRequestPage> createState() => _EditUniformRequestPageState();
}

class _EditUniformRequestPageState extends State<EditUniformRequestPage> {
  final _formKey = GlobalKey<FormState>();
  late String _gender;
  late String _course;
  late String _size;
  late String _studentId;
  late String _status;

  @override
  void initState() {
    super.initState();
    _gender = widget.requestData['gender'] ?? '';
    _course = widget.requestData['course'] ?? '';
    _size = widget.requestData['size'] ?? '';
    _studentId = widget.requestData['studentId'] ?? '';
    _status = widget.requestData['status'] ?? 'Pending';
  }

  Future<void> _saveEdit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final firestore = FirebaseFirestore.instance;

    // Update the request document
    await firestore.collection('uniform_requests').doc(widget.requestId).update({
      'gender': _gender,
      'course': _course,
      'size': _size,
      'studentId': _studentId,
      'status': _status,
    });

    // If status is Completed -> deduct inventory
    if (_status == 'Completed') {
      final inventoryRef = firestore.collection('uniform_inventory');
      final query = await inventoryRef
          .where('course', isEqualTo: _course)
          .where('gender', isEqualTo: _gender)
          .where('size', isEqualTo: _size)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        final currentStock = doc['count'] ?? 0;

        if (currentStock > 0) {
          await inventoryRef.doc(doc.id).update({
            'count': currentStock - 1,
          });
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("No stock left for this uniform")),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Uniform not found in inventory")),
          );
        }
      }
    }

    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Uniform Request')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            shrinkWrap: true,
            children: [
              TextFormField(
                initialValue: _gender,
                decoration: const InputDecoration(labelText: 'Gender'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Enter gender' : null,
                onSaved: (value) => _gender = value ?? '',
              ),
              TextFormField(
                initialValue: _course,
                decoration: const InputDecoration(labelText: 'Course'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Enter course' : null,
                onSaved: (value) => _course = value ?? '',
              ),
              TextFormField(
                initialValue: _size,
                decoration: const InputDecoration(labelText: 'Size'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Enter size' : null,
                onSaved: (value) => _size = value ?? '',
              ),
              TextFormField(
                initialValue: _studentId,
                decoration: const InputDecoration(labelText: 'Student Number'),
                validator: (value) => value == null || value.isEmpty
                    ? 'Enter Student Number'
                    : null,
                onSaved: (value) => _studentId = value ?? '',
              ),
              DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: const [
                  DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                  DropdownMenuItem(value: 'Approved', child: Text('Approved')),
                  DropdownMenuItem(value: 'Rejected', child: Text('Rejected')),
                  DropdownMenuItem(
                      value: 'Completed', child: Text('Completed')),
                ],
                onChanged: (value) =>
                    setState(() => _status = value ?? 'Pending'),
                onSaved: (value) => _status = value ?? 'Pending',
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveEdit,
                child: const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
