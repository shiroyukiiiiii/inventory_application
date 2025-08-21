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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Uniform Management'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Inventory'),
              Tab(text: 'Requests'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _InventoryTab(),
            UniformRequestsListPage(),
          ],
        ),
        floatingActionButton: Builder(
          builder: (context) {
            final tabIndex = DefaultTabController.of(context).index;
            // Only show the FAB on the Inventory tab
            return tabIndex == 0
                ? FloatingActionButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const UniformFormPage(),
                        ),
                      );
                    },
                    child: const Icon(Icons.add),
                  )
                : Container();
          },
        ),
      ),
    );
  }
}

class _InventoryTab extends StatelessWidget {
  const _InventoryTab();

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
    return StreamBuilder<List<Uniform>>(
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

class UniformRequestsListPage extends StatelessWidget {
  const UniformRequestsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('uniform_requests')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No uniform requests found.'));
        }
        final requests = snapshot.data!.docs;
        return ListView.builder(
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final data = requests[index].data() as Map<String, dynamic>;
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: Text('${data['userName'] ?? 'Unknown'} (${data['userId']})'),
                subtitle: Text(
                  'Gender: ${data['gender']}\n'
                  'Course: ${data['course']}\n'
                  'Size: ${data['size']}\n'
                  'Requested: ${data['timestamp'] != null ? (data['timestamp'] as Timestamp).toDate().toString() : 'N/A'}',
                ),
              ),
            );
          },
        );
      },
    );
  }
}
