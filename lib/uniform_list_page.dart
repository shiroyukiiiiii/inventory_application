import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/uniform.dart';
import 'edit_uniform_request_page.dart';

class UniformListPage extends StatefulWidget {
  const UniformListPage({super.key});

  @override
  State<UniformListPage> createState() => _UniformListPageState();
}

class _UniformListPageState extends State<UniformListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Listen to tab changes if needed (e.g. show/hide FAB)
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Uniform Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Inventory'),
            Tab(text: 'Requests'),
            Tab(text: 'Completed Orders'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _InventoryTab(),
          UniformRequestsListPage(),
          CompletedOrdersListPage(),
        ],
      ),
      floatingActionButton: _buildFab(),
    );
  }

  Widget? _buildFab() {
    // Show FAB only on the Inventory tab (index 0)
    if (_tabController.index == 0) {
      return FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const UniformFormPage()),
          );
        },
        child: const Icon(Icons.add),
      );
    }
    return null;
  }
}

class CompletedOrdersListPage extends StatelessWidget {
  const CompletedOrdersListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('completed_orders')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data?.docs;
        if (docs == null || docs.isEmpty) {
          return const Center(child: Text('No completed orders found.'));
        }
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data =
                docs[index].data() as Map<String, dynamic>? ?? <String, dynamic>{};
            final timestamp = data['timestamp'];
            String completedStr = 'N/A';
            if (timestamp is Timestamp) {
              completedStr = DateFormat('MMM d, yyyy hh:mm a')
                  .format(timestamp.toDate());
            }
            return Card(
              margin:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: Text(
                    '${data['userName'] ?? 'Unknown'} (${data['userId'] ?? ''})'),
                subtitle: Text(
                  'Gender: ${data['gender'] ?? ''}\n'
                  'Course: ${data['course'] ?? ''}\n'
                  'Size: ${data['size'] ?? ''}\n'
                  'Completed: $completedStr',
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _InventoryTab extends StatelessWidget {
  const _InventoryTab({super.key});

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
        final uniforms = snapshot.data;
        if (uniforms == null || uniforms.isEmpty) {
          return const Center(child: Text('No uniforms found.'));
        }
        return ListView.builder(
          itemCount: uniforms.length,
          itemBuilder: (context, index) {
            final uniform = uniforms[index];
            return ListTile(
              title: Text(
                  '${uniform.gender} - ${uniform.course} (${uniform.size})'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Qty: ${uniform.quantity}'),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    tooltip: 'Delete',
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Uniform'),
                          content: const Text(
                              'Are you sure you want to delete this uniform?'),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(context, true),
                              child: const Text('Delete',
                                  style:
                                      TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await FirebaseFirestore.instance
                            .collection('uniforms')
                            .doc(uniform.id)
                            .delete();
                      }
                    },
                  ),
                ],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        UniformFormPage(uniform: uniform),
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

  String _gender = '';
  String _course = '';
  String _size = '';
  int _quantity = 0;

  @override
  void initState() {
    super.initState();
    if (widget.uniform != null) {
      _gender = widget.uniform!.gender;
      _course = widget.uniform!.course;
      _size = widget.uniform!.size;
      _quantity = widget.uniform!.quantity;
    }
  }

  Future<void> _saveUniform() async {
    if (_formKey.currentState?.validate() != true) return;
    _formKey.currentState!.save();

    final uniformsRef = FirebaseFirestore.instance.collection('uniforms');

    final uniformData = {
      'gender': _gender,
      'course': _course,
      'size': _size,
      'quantity': _quantity,
    };

    if (widget.uniform == null) {
      await uniformsRef.add(uniformData);
    } else {
      await uniformsRef.doc(widget.uniform!.id).update(uniformData);
    }

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _deleteUniform() async {
    if (widget.uniform == null) return;
    await FirebaseFirestore.instance
        .collection('uniforms')
        .doc(widget.uniform!.id)
        .delete();
    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  String? _validateGender(String? value) {
    if (_gender.isEmpty) return 'Please select gender';
    return null;
  }

  String? _validateCourse(String? value) {
    if (_course.isEmpty) return 'Please select course';
    return null;
  }

  String? _validateSize(String? value) {
    if (value == null || value.isEmpty) return 'Please select size';
    return null;
  }

  String? _validateQuantity(String? value) {
    if (value == null || value.isEmpty) return 'Enter quantity';
    final n = int.tryParse(value);
    if (n == null || n < 0) return 'Enter a valid number';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.uniform == null ? 'Add Uniform' : 'Edit Uniform'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Gender
              const Text('Gender', style: TextStyle(fontSize: 16)),
              ...['Male', 'Female'].map((g) {
                return RadioListTile<String>(
                  title: Text(g),
                  value: g,
                  groupValue: _gender,
                  onChanged: (value) {
                    setState(() {
                      _gender = value ?? '';
                    });
                  },
                );
              }).toList(),
              if (_validateGender(null) != null)
                Text(_validateGender(null)!,
                    style: const TextStyle(color: Colors.red)),

              const SizedBox(height: 12),

              // Course
              const Text('Course', style: TextStyle(fontSize: 16)),
              ...['BSCRIM', 'ABCOM', 'BSCS'].map((c) {
                return RadioListTile<String>(
                  title: Text(c),
                  value: c,
                  groupValue: _course,
                  onChanged: (value) {
                    setState(() {
                      _course = value ?? '';
                    });
                  },
                );
              }).toList(),
              if (_validateCourse(null) != null)
                Text(_validateCourse(null)!,
                    style: const TextStyle(color: Colors.red)),

              const SizedBox(height: 12),

              // Size dropdown
              DropdownButtonFormField<String>(
                value: _size.isNotEmpty ? _size : null,
                decoration: const InputDecoration(labelText: 'Size'),
                items: ['XS', 'S', 'M', 'L', 'XL', 'XXL']
                    .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(s),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _size = value ?? '';
                  });
                },
                validator: _validateSize,
                onSaved: (value) {
                  _size = value ?? '';
                },
              ),

              const SizedBox(height: 12),

              // Quantity
              TextFormField(
                initialValue: _quantity.toString(),
                decoration: const InputDecoration(labelText: 'Quantity'),
                keyboardType: TextInputType.number,
                validator: _validateQuantity,
                onSaved: (value) {
                  _quantity = int.parse(value!);
                },
              ),

              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveUniform,
                      child: Text(widget.uniform == null ? 'Add' : 'Update'),
                    ),
                  ),
                  if (widget.uniform != null) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        onPressed: _deleteUniform,
                        child: const Text('Delete'),
                      ),
                    ),
                  ],
                ],
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
        final docs = snapshot.data?.docs;
        if (docs == null || docs.isEmpty) {
          return const Center(child: Text('No uniform requests found.'));
        }
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data =
                docs[index].data() as Map<String, dynamic>? ?? <String, dynamic>{};
            final timestamp = data['timestamp'];
            String reqStr = 'N/A';
            if (timestamp is Timestamp) {
              reqStr = DateFormat('MMM d, yyyy hh:mm a')
                  .format(timestamp.toDate());
            }
            return Card(
              margin:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: Text(data['userName'] ?? 'Unknown'),
                subtitle: Text(
                  'Gender: ${data['gender'] ?? ''}\n'
                  'Course: ${data['course'] ?? ''}\n'
                  'Size: ${data['size'] ?? ''}\n'
                  'Student #: ${data['studentId'] ?? ''}\n'
                  'Requested: $reqStr\n'
                  'Status: ${data['status'] ?? 'Pending'}\n'
                  'Order Id: ${docs[index].id}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon:
                          const Icon(Icons.edit, color: Colors.blue),
                      tooltip: 'Edit Request',
                      onPressed: () async {
                        final result = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditUniformRequestPage(
                              requestId: docs[index].id,
                              requestData: data,
                            ),
                          ),
                        );
                        if (result == true) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('Request updated successfully!')),
                          );
                        }
                      },
                    ),
                    IconButton(
                      icon:
                          const Icon(Icons.delete, color: Colors.red),
                      tooltip: 'Delete Request',
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Request'),
                            content: const Text(
                                'Are you sure you want to delete this request?'),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(context, true),
                                child: const Text('Delete',
                                    style:
                                        TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await FirebaseFirestore.instance
                              .collection('uniform_requests')
                              .doc(docs[index].id)
                              .delete();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Request deleted.')),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
