import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/uniform.dart';
import 'admin_qr_confirmation.dart';
import 'services/emailjs_service.dart';

class UniformListPage extends StatelessWidget {
  const UniformListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4, // ✅ 4 tabs
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Uniform Management'),
          actions: [
            IconButton(
              icon: const Icon(Icons.qr_code_scanner),
              tooltip: 'QR Confirmation',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminQrConfirmationPage(),
                  ),
                );
              },
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Inventory'),
              Tab(text: 'Requests'),
              Tab(text: 'Approved'),
              Tab(text: 'Completed Orders'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _InventoryTab(),
            UniformRequestsListPage(),
            ApprovedOrdersListPage(),
            CompletedOrdersListPage(),
          ],
        ),
        floatingActionButton: Builder(
          builder: (context) {
            final tabIndex = DefaultTabController.of(context).index;
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

/// ============================
/// Inventory Tab
/// ============================
class _InventoryTab extends StatelessWidget {
  const _InventoryTab();

  Stream<List<Uniform>> getUniforms() {
    return FirebaseFirestore.instance
        .collection('uniforms')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Uniform.fromMap(doc.data(), doc.id)).toList());
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
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Delete',
                                  style: TextStyle(color: Colors.red)),
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
            );
          },
        );
      },
    );
  }
}

/// ============================
/// Uniform Form Page (Add/Edit)
/// ============================
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

  Future<void> _deleteUniform() async {
    if (widget.uniform != null) {
      final uniformsRef = FirebaseFirestore.instance.collection('uniforms');
      await uniformsRef.doc(widget.uniform!.id).delete();
      if (mounted) Navigator.pop(context);
    }
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
      appBar:
          AppBar(title: Text(widget.uniform == null ? 'Add Uniform' : 'Edit Uniform')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text('Gender', style: TextStyle(fontSize: 16)),
              ...['Male', 'Female'].map((gender) => RadioListTile<String>(
                    title: Text(gender),
                    value: gender,
                    groupValue: _gender,
                    onChanged: (value) {
                      setState(() {
                        _gender = value ?? '';
                      });
                    },
                  )),
              const Text('Course', style: TextStyle(fontSize: 16)),
              ...['BSCRIM', 'ABCOM', 'BSCS'].map((course) => RadioListTile<String>(
                    title: Text(course),
                    value: course,
                    groupValue: _course,
                    onChanged: (value) {
                      setState(() {
                        _course = value ?? '';
                      });
                    },
                  )),
              DropdownButtonFormField<String>(
                value: _size.isNotEmpty ? _size : null,
                decoration: const InputDecoration(labelText: 'Size'),
                items: ['XS', 'S', 'M', 'L', 'XL', 'XXL']
                    .map((size) => DropdownMenuItem(
                          value: size,
                          child: Text(size),
                        ))
                    .toList(),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Select size' : null,
                onChanged: (value) {
                  setState(() {
                    _size = value ?? '';
                  });
                },
                onSaved: (value) => _size = value ?? '',
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
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveUniform,
                      child: Text(widget.uniform == null ? 'Add' : 'Update'),
                    ),
                  ),
                  if (widget.uniform != null) ...[
                    const SizedBox(width: 10),
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

/// ============================
/// Requests Tab
/// ============================
class UniformRequestsListPage extends StatelessWidget {
  const UniformRequestsListPage({super.key});

  Future<void> _approveRequest(String id, Map<String, dynamic> data, BuildContext context) async {
    await FirebaseFirestore.instance.collection('uniform_requests').doc(id).update({
      'status': 'Approved',
      'approvedAt': Timestamp.now(),
    });
    try {
      await EmailJsService.sendApprovalEmail(
        toEmail: data['email'] ?? '',
        toName: data['userName'] ?? '',
        studentNumber: data['studentId'] ?? '',
        studentName: data['userName'] ?? '',
        gender: data['gender'] ?? '',
        course: data['course'] ?? '',
        size: data['size'] ?? '',
        qrCode: data['qrCode'] ?? '',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Approval email sent!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send approval email: $e')),
      );
    }
  }

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

        final requests = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['status'] != 'Approved' && data['status'] != 'Completed';
        }).toList();

        if (requests.isEmpty) {
          return const Center(child: Text('No pending requests.'));
        }

        return ListView.builder(
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final doc = requests[index];
            final data = doc.data() as Map<String, dynamic>;
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: Text('${data['userName'] ?? 'Unknown'}'),
                subtitle: Text(
                  'Email: ${data['email'] ?? ''}\n'
                  'Course: ${data['course'] ?? ''}\n'
                  'Size: ${data['size'] ?? ''}\n'
                  'Student ID: ${data['studentId'] ?? ''}\n'
                  'Requested: ${data['timestamp'] != null ? (data['timestamp'] as Timestamp).toDate().toString() : 'N/A'}\n'
                  'Status: ${data['status'] ?? 'Pending'}',
                ),
                trailing: ElevatedButton(
                  onPressed: () => _approveRequest(doc.id, data, context),
                  child: const Text("Approve"),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// ============================
/// Approved Orders Tab
/// ============================
class ApprovedOrdersListPage extends StatelessWidget {
  const ApprovedOrdersListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('uniform_requests')
          .orderBy('approvedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No approved requests.'));
        }

        final approved = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['status'] == 'Approved';
        }).toList();

        if (approved.isEmpty) {
          return const Center(child: Text('No approved requests.'));
        }

        return ListView.builder(
          itemCount: approved.length,
          itemBuilder: (context, index) {
            final data = approved[index].data() as Map<String, dynamic>;
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: Text('${data['userName'] ?? 'Unknown'}'),
                subtitle: Text(
                  'Course: ${data['course'] ?? ''}\n'
                  'Size: ${data['size'] ?? ''}\n'
                  'Approved: ${data['approvedAt'] != null ? (data['approvedAt'] as Timestamp).toDate().toString() : 'N/A'}',
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// ============================
/// Completed Orders Tab
/// ============================
class CompletedOrdersListPage extends StatelessWidget {
  const CompletedOrdersListPage({super.key});

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
          return const Center(child: Text('No completed orders found.'));
        }

        final orders = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['status'] == 'Completed';
        }).toList();

        if (orders.isEmpty) {
          return const Center(child: Text('No completed orders.'));
        }

        return ListView.builder(
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final data = orders[index].data() as Map<String, dynamic>;
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title:
                    Text('${data['userName'] ?? 'Unknown'} (${data['studentId'] ?? ''})'),
                subtitle: Text(
                  'Course: ${data['course'] ?? ''}\n'
                  'Size: ${data['size'] ?? ''}\n'
                  'Completed: ${data['timestamp'] != null ? (data['timestamp'] as Timestamp).toDate().toString() : 'N/A'}',
                ),
              ),
            );
          },
        );
      },
    );
  }
}
