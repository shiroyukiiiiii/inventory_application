import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/uniform.dart';

class UniformListPage extends StatelessWidget {
  const UniformListPage({super.key});

  Stream<List<Uniform>> getUniforms() {
    return FirebaseFirestore.instance
        .collection('uniforms')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Uniform.fromMap(doc.data(), doc.id))
            .toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Uniform Inventory')),
      body: StreamBuilder<List<Uniform>>(
        stream: getUniforms(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No uniforms found.'));
          }
          final uniforms = snapshot.data!;
          return ListView.builder(
            itemCount: uniforms.length,
            itemBuilder: (context, index) {
              final uniform = uniforms[index];
              return ListTile(
                title: Text('${uniform.gender} - ${uniform.course} (${uniform.size})'),
                trailing: Text('Qty: ${uniform.quantity}'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UniformFormPage(uniform: uniform),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const UniformFormPage(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class UniformFormPage extends StatefulWidget {
  final Uniform? uniform;
  const UniformFormPage({super.key, this.uniform});

  @override
  State<UniformFormPage> createState() => _UniformFormPageState();
}

class _UniformFormPageState extends State<UniformFormPage> {
  final _formKey = GlobalKey<FormState>();
  late String _gender;
  late String _course;
  late String _size;
  late int _quantity;

  @override
  void initState() {
    super.initState();
    _gender = widget.uniform?.gender ?? '';
    _course = widget.uniform?.course ?? '';
    _size = widget.uniform?.size ?? '';
    _quantity = widget.uniform?.quantity ?? 0;
  }

  Future<void> _saveUniform() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final uniform = Uniform(
        id: widget.uniform?.id ?? '',
        gender: _gender,
        course: _course,
        size: _size,
        quantity: _quantity,
      );
      final uniformsRef = FirebaseFirestore.instance.collection('uniforms');
      if (widget.uniform == null) {
        await uniformsRef.add(uniform.toMap());
      } else {
        await uniformsRef.doc(uniform.id).update(uniform.toMap());
      }
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.uniform == null ? 'Add Uniform' : 'Edit Uniform')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Removed 'Type' field since uniforms are sets
              TextFormField(
                initialValue: _gender,
                decoration: const InputDecoration(labelText: 'Gender'),
                validator: (value) => value == null || value.isEmpty ? 'Enter gender' : null,
                onSaved: (value) => _gender = value!,
              ),
              TextFormField(
                initialValue: _course,
                decoration: const InputDecoration(labelText: 'Course'),
                validator: (value) => value == null || value.isEmpty ? 'Enter course' : null,
                onSaved: (value) => _course = value!,
              ),
              TextFormField(
                initialValue: _size,
                decoration: const InputDecoration(labelText: 'Size'),
                validator: (value) => value == null || value.isEmpty ? 'Enter size' : null,
                onSaved: (value) => _size = value!,
              ),
              TextFormField(
                initialValue: _quantity.toString(),
                decoration: const InputDecoration(labelText: 'Quantity'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Enter quantity';
                  final n = int.tryParse(value);
                  if (n == null || n < 0) return 'Enter a valid quantity';
                  return null;
                },
                onSaved: (value) => _quantity = int.parse(value!),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveUniform,
                child: Text(widget.uniform == null ? 'Add' : 'Update'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
