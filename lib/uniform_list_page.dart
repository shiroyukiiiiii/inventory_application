import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/uniform.dart';
import 'admin_qr_confirmation.dart';
import 'services/emailjs_service.dart';

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
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // rebuild when tab changes to show/hide FAB
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
      backgroundColor: Colors.grey[100],

      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 2, 167, 30),
        title: const Text(
          'Uniform Management',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
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
      ),

      // ✅ The content of each tab
      body: TabBarView(
        controller: _tabController,
        children: const [
          _InventoryTab(),
          UniformRequestsListPage(),
          ApprovedOrdersListPage(),
          CompletedOrdersListPage(),
        ],
      ),

      // ✅ Bottom Tabs with icons
      bottomNavigationBar: Container(
        color: const Color.fromARGB(255, 2, 167, 30),
        child: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: const Color.fromARGB(255, 0, 136, 255),
          unselectedLabelColor: Colors.white,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [
            Tab(icon: Icon(Icons.inventory), text: 'Inventory'),
            Tab(icon: Icon(Icons.pending_actions), text: 'Requests'),
            Tab(icon: Icon(Icons.check_circle), text: 'Approved'),
            Tab(icon: Icon(Icons.done_all), text: 'Completed'),
          ],
        ),
      ),

      // ✅ Floating Add Button (only for Inventory tab)
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton(
              backgroundColor: const Color.fromARGB(255, 0, 145, 255),
              tooltip: 'Add Uniform',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UniformFormPage(),
                  ),
                );
              },
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}

/// ============================
/// Inventory Tab (Gender-separated summary)
/// ============================
class _InventoryTab extends StatelessWidget {
  const _InventoryTab();

  Stream<List<Uniform>> getUniforms() {
    return FirebaseFirestore.instance.collection('uniforms').snapshots().map(
        (snapshot) => snapshot.docs
            .map((doc) => Uniform.fromMap(doc.data(), doc.id))
            .toList());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: StreamBuilder<List<Uniform>>(
        stream: getUniforms(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF00B4FF)),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No uniforms found.',
                style: TextStyle(color: Colors.black54, fontSize: 18),
              ),
            );
          }

          final uniforms = snapshot.data!;
          final totalStock = uniforms.fold<int>(0, (a, u) => a + u.quantity);

          final List<String> courses = ['BSCS', 'BSCRIM', 'ABCOM'];
          final genders = ['Male', 'Female'];

          // Course → Gender → Size counts
          final Map<String, Map<String, Map<String, int>>> summary = {
            for (var course in courses)
              course: {
                for (var gender in genders)
                  gender: {'S': 0, 'M': 0, 'L': 0, 'XL': 0, 'Total': 0},
              }
          };

          for (var uniform in uniforms) {
            final course = uniform.course.toUpperCase().trim();
            final gender = uniform.gender.toUpperCase().trim();
            final size = uniform.size.toUpperCase().trim();
            final qty = uniform.quantity;

            if (summary.containsKey(course)) {
              final genderKey = gender == 'FEMALE' ? 'Female' : 'Male';
              if (summary[course]![genderKey]!.containsKey(size)) {
                summary[course]![genderKey]![size] =
                    (summary[course]![genderKey]![size] ?? 0) + qty;
              }
              summary[course]![genderKey]!['Total'] =
                  (summary[course]![genderKey]!['Total'] ?? 0) + qty;
            }
          }

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    "Inventory Summary",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00A86B),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _SummaryCard(
                        title: "Total Uniforms",
                        value: uniforms.length.toString(),
                        icon: Icons.inventory_2_outlined,
                        color: const Color(0xFF00A86B),
                      ),
                      const SizedBox(width: 12),
                      _SummaryCard(
                        title: "Total Stock",
                        value: totalStock.toString(),
                        icon: Icons.check_circle_outline,
                        color: const Color(0xFF00B4FF),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    "Per Course Summary (by Gender)",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00A86B),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Render each course
                  Column(
                    children: summary.entries.map((entry) {
                      final course = entry.key;
                      final genderData = entry.value;

                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 25, vertical: 20),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFB2EBF2)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.15),
                              blurRadius: 10,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              course,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF00A86B),
                              ),
                            ),
                            const SizedBox(height: 15),

                            // Separate Male & Female sections
                            ...genderData.entries.map((g) {
                              final gender = g.key;
                              final data = g.value;
                              final color = gender == 'Male'
                                  ? const Color(0xFF00A86B)
                                  : const Color(0xFF00B4FF);

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    gender,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: color,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    "Total Stock: ${data['Total']}",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    "By Size",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    alignment: WrapAlignment.center,
                                    spacing: 20,
                                    children: ['S', 'M', 'L', 'XL'].map((size) {
                                      return Column(
                                        children: [
                                          Text(
                                            size,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            data[size].toString(),
                                            style: const TextStyle(
                                              fontSize: 15,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                  const SizedBox(height: 18),
                                ],
                              );
                            }),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Summary Card Widget
class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        color: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, size: 30, color: Colors.white),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold),
              ),
              Text(
                title,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Summary Section for Course & Size
class _SummarySection extends StatelessWidget {
  final String title;
  final Map<String, int> data;

  const _SummarySection({required this.title, required this.data});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal)),
            const SizedBox(height: 6),
            if (data.isEmpty)
              const Text('No data available',
                  style: TextStyle(color: Colors.grey)),
            ...data.entries.map((entry) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(entry.key,
                          style: const TextStyle(
                              fontWeight: FontWeight.w500, fontSize: 14)),
                      Text(entry.value.toString(),
                          style: const TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                )),
          ],
        ),
      ),
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
      appBar: AppBar(
          title: Text(widget.uniform == null ? 'Add Uniform' : 'Edit Uniform')),
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
              ...['BSCRIM', 'ABCOM', 'BSCS']
                  .map((course) => RadioListTile<String>(
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
                initialValue: _size.isNotEmpty ? _size : null,
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
/// Requests Tab with Search
/// ============================
class UniformRequestsListPage extends StatefulWidget {
  const UniformRequestsListPage({super.key});

  @override
  State<UniformRequestsListPage> createState() =>
      _UniformRequestsListPageState();
}

class _UniformRequestsListPageState extends State<UniformRequestsListPage> {
  String searchQuery = '';

  Future<void> _approveRequest(
      String id, Map<String, dynamic> data, BuildContext context) async {
    await FirebaseFirestore.instance
        .collection('uniform_requests')
        .doc(id)
        .update({
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Search by name or student ID...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12))),
            ),
            onChanged: (value) {
              setState(() {
                searchQuery = value.toLowerCase();
              });
            },
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
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
                final status = data['status'] ?? '';
                final name = (data['userName'] ?? '').toString().toLowerCase();
                final id = (data['studentId'] ?? '').toString().toLowerCase();
                final matchesSearch =
                    name.contains(searchQuery) || id.contains(searchQuery);
                return status != 'Approved' &&
                    status != 'Completed' &&
                    matchesSearch;
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
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          ),
        ),
      ],
    );
  }
}

/// ============================
/// Approved Orders Tab with Search
/// ============================
class ApprovedOrdersListPage extends StatefulWidget {
  const ApprovedOrdersListPage({super.key});

  @override
  State<ApprovedOrdersListPage> createState() => _ApprovedOrdersListPageState();
}

class _ApprovedOrdersListPageState extends State<ApprovedOrdersListPage> {
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Search by name or student ID...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12))),
            ),
            onChanged: (value) {
              setState(() {
                searchQuery = value.toLowerCase();
              });
            },
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
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
                final status = data['status'] ?? '';
                final name = (data['userName'] ?? '').toString().toLowerCase();
                final id = (data['studentId'] ?? '').toString().toLowerCase();
                final matchesSearch =
                    name.contains(searchQuery) || id.contains(searchQuery);
                return status == 'Approved' && matchesSearch;
              }).toList();

              if (approved.isEmpty) {
                return const Center(child: Text('No approved requests.'));
              }

              return ListView.builder(
                itemCount: approved.length,
                itemBuilder: (context, index) {
                  final data = approved[index].data() as Map<String, dynamic>;
                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          ),
        ),
      ],
    );
  }
}

/// ============================
/// Completed Orders Tab with Search
/// ============================
class CompletedOrdersListPage extends StatefulWidget {
  const CompletedOrdersListPage({super.key});

  @override
  State<CompletedOrdersListPage> createState() =>
      _CompletedOrdersListPageState();
}

class _CompletedOrdersListPageState extends State<CompletedOrdersListPage> {
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Search by name or student ID...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12))),
            ),
            onChanged: (value) {
              setState(() {
                searchQuery = value.toLowerCase();
              });
            },
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
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
                final status = data['status'] ?? '';
                final name = (data['userName'] ?? '').toString().toLowerCase();
                final id = (data['studentId'] ?? '').toString().toLowerCase();
                final matchesSearch =
                    name.contains(searchQuery) || id.contains(searchQuery);
                return status == 'Completed' && matchesSearch;
              }).toList();

              if (orders.isEmpty) {
                return const Center(child: Text('No completed orders.'));
              }

              return ListView.builder(
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final data = orders[index].data() as Map<String, dynamic>;
                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      title: Text(
                          '${data['userName'] ?? 'Unknown'} (${data['studentId'] ?? ''})'),
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
          ),
        ),
      ],
    );
  }
}
