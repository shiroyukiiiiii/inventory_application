import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:inventory_application/admin_login_page.dart';
import '../models/uniform.dart';
import 'admin_qr_confirmation.dart';
import 'services/emailjs_service.dart';
import 'package:intl/intl.dart';
import 'package:flutter/gestures.dart';

class UniformListPage extends StatefulWidget {
  const UniformListPage({super.key});

  @override
  State<UniformListPage> createState() => _UniformListPageState();
}

class _UniformListPageState extends State<UniformListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPage = 'tabs'; // default view

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openDrawerOption(BuildContext context, String option) {
    Navigator.pop(context);
    setState(() {
      _selectedPage = option;
    });
  }

  Widget _getSelectedPage() {
    switch (_selectedPage) {
      case 'inventorySummary':
        return const _InventoryTab();
      case 'stock_history':
        return const HistoryStockReportTab(); // new empty table
      case 'tabs':
      default:
        return TabBarView(
          controller: _tabController,
          children: const [
            UniformRequestsListPage(),
            ApprovedOrdersListPage(),
            CompletedOrdersListPage(),
            InventoryPage(),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],

      // Drawer Menu
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(color: Color(0xFF00A86B)),
                child: const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'More Menu',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              ListTile(
                leading: const Icon(Icons.summarize, color: Colors.green),
                title: const Text('Inventory Summary'),
                onTap: () => _openDrawerOption(context, 'inventorySummary'),
              ),

              ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: const Text('Approved Orders'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedPage = 'tabs';
                    _tabController.index = 1;
                  });
                },
              ),

              ListTile(
                leading: const Icon(Icons.done_all, color: Colors.blue),
                title: const Text('Completed Orders'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedPage = 'tabs';
                    _tabController.index = 2;
                  });
                },
              ),

              ListTile(
                leading: const Icon(Icons.history, color: Colors.orange),
                title: const Text('History Stock Report'),
                onTap: () {
                  Navigator.pop(context); // close drawer
                  setState(() {
                    _selectedPage = 'stock_history'; // shows inside the page
                  });
                },
              ),

              const Spacer(), // pushes logout to the bottom

              // Logout button
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Logout'),
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Logout Confirmation'),
                      content: const Text('Are you sure you want to log out?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text(
                            'Logout',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await FirebaseAuth.instance.signOut();
                    if (mounted) {
                      Navigator.of(context)
                          .pushNamedAndRemoveUntil('/login', (route) => false);
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),

      // AppBar
      appBar: AppBar(
        backgroundColor: const Color(0xFF00A86B),
        title: const Text(
          'Uniform Management',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),

      // Body
      body: _getSelectedPage(),

      // Bottom Tab Bar
      bottomNavigationBar: _selectedPage == 'tabs'
          ? Container(
              color: const Color(0xFF00A86B),
              child: TabBar(
                controller: _tabController,
                indicatorColor: const Color.fromARGB(255, 0, 55, 255),
                labelColor: const Color.fromARGB(255, 0, 3, 5),
                unselectedLabelColor: Colors.white,
                labelStyle:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                tabs: const [
                  Tab(icon: Icon(Icons.pending_actions), text: 'Requests'),
                  Tab(icon: Icon(Icons.check_circle), text: 'Approved'),
                  Tab(icon: Icon(Icons.done_all), text: 'Completed'),
                  Tab(icon: Icon(Icons.inventory), text: 'Inventory'),
                ],
              ),
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth > 700;

                return SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 900),
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
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              _SummaryCard(
                                title: "Total Uniforms",
                                value: uniforms.length.toString(),
                                icon: Icons.inventory_2_outlined,
                                color: const Color(0xFF00A86B),
                              ),
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
                          Column(
                            children: summary.entries.map((entry) {
                              final course = entry.key;
                              final genderData = entry.value;
                              return Container(
                                margin:
                                    const EdgeInsets.symmetric(vertical: 10),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 25, vertical: 20),
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                      color: const Color(0xFFB2EBF2)),
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
                                    ...genderData.entries.map((g) {
                                      final gender = g.key;
                                      final data = g.value;
                                      final color = gender == 'Male'
                                          ? const Color(0xFF00A86B)
                                          : const Color(0xFF00B4FF);
                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
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
                                            spacing: 25,
                                            children: ['S', 'M', 'L', 'XL']
                                                .map((size) {
                                              return Column(
                                                children: [
                                                  Text(
                                                    size,
                                                    style: const TextStyle(
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.bold,
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
                          const SizedBox(height: 20),

                          // SIZE box placed at the BOTTOM of Inventory Summary as requested
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 255, 255, 255)
                                  .withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: const [
                                Text(
                                  "SIZE",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text("S - SMALL",
                                    style: TextStyle(fontSize: 16)),
                                Text("M - MEDIUM",
                                    style: TextStyle(fontSize: 16)),
                                Text("L - LARGE",
                                    style: TextStyle(fontSize: 16)),
                                Text("XL - DOUBLE XL",
                                    style: TextStyle(fontSize: 16)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
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
    return Card(
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
      await FirebaseFirestore.instance
          .collection('uniforms')
          .doc(widget.uniform!.id)
          .delete();
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _saveUniform() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    // 🚫 Additional Validation
    if (_course.isEmpty || _gender.isEmpty || _size.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All fields are required.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Quantity must be greater than 0.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_quantity > 500) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Quantity cannot exceed 500 per entry.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final uniformsRef = FirebaseFirestore.instance.collection('uniforms');
    String message = '';

    if (widget.uniform != null) {
      // 🔹 Editing existing uniform
      await uniformsRef.doc(widget.uniform!.id).update({
        'course': _course,
        'gender': _gender,
        'size': _size,
        'quantity': _quantity,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      message = 'Stock updated successfully!';
    } else {
      // 🔹 Adding new uniform
      final existingQuery = await uniformsRef
          .where('course', isEqualTo: _course)
          .where('gender', isEqualTo: _gender)
          .where('size', isEqualTo: _size)
          .limit(1)
          .get();

      if (existingQuery.docs.isNotEmpty) {
        final existingDoc = existingQuery.docs.first;
        await uniformsRef.doc(existingDoc.id).update({
          'quantity': FieldValue.increment(_quantity),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        message = 'Stock updated successfully!';
      } else {
        await uniformsRef.add({
          'course': _course,
          'gender': _gender,
          'size': _size,
          'quantity': _quantity,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        message = 'New stock added successfully!';
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.teal,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
      Navigator.pop(context);
    }
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.teal),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
        ),
      ],
    );
  }

  Widget _buildRadioOptions(
      {required String title,
      required List<String> options,
      required String groupValue,
      required ValueChanged<String?> onChanged}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ...options.map((opt) => RadioListTile<String>(
                  title: Text(opt),
                  value: opt,
                  groupValue: groupValue,
                  onChanged: onChanged,
                  activeColor: Colors.teal,
                )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.uniform == null ? 'Add Uniform' : 'Edit Uniform'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Gender Section
              _buildRadioOptions(
                  title: 'Gender',
                  options: ['Male', 'Female'],
                  groupValue: _gender,
                  onChanged: (val) => setState(() => _gender = val ?? '')),

              // Course Section
              _buildRadioOptions(
                  title: 'Course',
                  options: ['BSCRIM', 'ABCOM', 'BSCS'],
                  groupValue: _course,
                  onChanged: (val) => setState(() => _course = val ?? '')),

              // Size Dropdown
              Card(
                margin: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: DropdownButtonFormField<String>(
                    initialValue: _size.isNotEmpty ? _size : null,
                    decoration: InputDecoration(
                      labelText: 'Size',
                      prefixIcon:
                          const Icon(Icons.straighten, color: Colors.teal),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    items: ['S', 'M', 'L', 'XL', 'XXL']
                        .map((size) => DropdownMenuItem(
                              value: size,
                              child: Text(size),
                            ))
                        .toList(),
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'Please select a size';
                      }
                      return null;
                    },
                    onChanged: (val) => setState(() => _size = val ?? ''),
                  ),
                ),
              ),

              // Quantity
              Card(
                margin: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextFormField(
                    initialValue: _quantity.toString(),
                    decoration: InputDecoration(
                      labelText: 'Quantity',
                      prefixIcon: const Icon(Icons.confirmation_num,
                          color: Colors.teal),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Enter quantity';
                      final n = int.tryParse(val);
                      if (n == null || n < 0) return 'Enter a valid quantity';
                      return null;
                    },
                    onSaved: (val) => _quantity = int.parse(val!),
                  ),
                ),
              ),

              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _saveUniform,
                      icon: const Icon(Icons.save, color: Colors.white),
                      label: Text(
                        widget.uniform == null ? 'Add Stock' : 'Update Stock',
                        style: const TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  if (widget.uniform != null) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _deleteUniform,
                        icon: const Icon(Icons.delete),
                        label: const Text('Delete Stock'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
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
  int rowsPerPage = 10;
  int currentPage = 0;

  // Helper function to format timestamp
  String formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'N/A';
    final date = timestamp.toDate();
    return DateFormat('MMM/dd/yyyy hh:mm a')
        .format(date); // Oct/15/2025 03:45 PM
  }

  Future<void> _approveRequest(
    String id,
    Map<String, dynamic> data,
    BuildContext context,
  ) async {
    final firestore = FirebaseFirestore.instance;

    try {
      final String course = (data['course'] ?? '').toString().trim();
      final String size = (data['size'] ?? '').toString().trim();
      final String gender = (data['gender'] ?? '').toString().trim();

      if (course.isEmpty || size.isEmpty || gender.isEmpty) {
        throw Exception('Invalid course, size, or gender values.');
      }

      final uniformQuery = await firestore
          .collection('uniforms')
          .where('course', isEqualTo: course)
          .where('gender', isEqualTo: gender)
          .where('size', isEqualTo: size)
          .limit(1)
          .get();

      if (uniformQuery.docs.isEmpty) {
        throw Exception('No uniform found for $course - $gender - $size');
      }

      final uniformDoc = uniformQuery.docs.first.reference;
      final requestRef = firestore.collection('uniform_requests').doc(id);

      await firestore.runTransaction((transaction) async {
        final uniformSnap = await transaction.get(uniformDoc);
        if (!uniformSnap.exists) throw Exception('Uniform no longer exists!');
        final currentStock = (uniformSnap.data()?['quantity'] ?? 0) as int;
        if (currentStock <= 0) throw Exception('No stock available.');

        final requestSnap = await transaction.get(requestRef);
        final currentStatus =
            (requestSnap.data()?['status'] ?? 'Pending').toString();
        if (currentStatus == 'Approved' || currentStatus == 'Completed') {
          throw Exception('Request already approved or completed.');
        }

        transaction.update(uniformDoc, {'quantity': currentStock - 1});
        transaction.update(requestRef, {
          'status': 'Approved',
          'approvedAt': FieldValue.serverTimestamp(),
        });
      });

      await EmailJsService.sendApprovalEmail(
        toEmail: data['email'] ?? '',
        toName: data['userName'] ?? '',
        studentNumber: data['studentId'] ?? '',
        studentName: data['userName'] ?? '',
        gender: data['gender'] ?? '',
        course: data['course'] ?? '',
        size: data['size'] ?? '',
        qrCode: data['qrCode'] ?? '',
        orderQuantity: data['orderQuantity'] ?? 1, // Add the required argument
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                '✅ Approved $course - $gender - $size. Stock deducted and email sent!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error approving request: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 700;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  "Uniform Requests",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00A86B),
                  ),
                ),
                const SizedBox(height: 16),

                // Search + Rows per page
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: isDesktop ? 250 : 180,
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search',
                          prefixIcon: const Icon(Icons.search,
                              color: Color(0xFF00B4FF)),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 16),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none),
                        ),
                        onChanged: (value) {
                          setState(() {
                            searchQuery = value.toLowerCase();
                            currentPage = 0;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black12),
                      ),
                      child: DropdownButton<int>(
                        value: rowsPerPage,
                        underline: const SizedBox(),
                        items: const [
                          DropdownMenuItem(value: 10, child: Text("10")),
                          DropdownMenuItem(value: 50, child: Text("50")),
                          DropdownMenuItem(value: 100, child: Text("100")),
                          DropdownMenuItem(value: -1, child: Text("ALL")),
                        ],
                        onChanged: (value) {
                          setState(() {
                            rowsPerPage = value!;
                            currentPage = 0;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('uniform_requests')
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator(
                                color: Color(0xFF00B4FF)));
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(
                            child: Text('No uniform requests found.'));
                      }

                      final requests = snapshot.data!.docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final status = data['status'] ?? '';

                        final name =
                            (data['userName'] ?? '').toString().toLowerCase();
                        final studentId =
                            (data['studentId'] ?? '').toString().toLowerCase();
                        final email =
                            (data['email'] ?? '').toString().toLowerCase();
                        final course =
                            (data['course'] ?? '').toString().toLowerCase();
                        final gender =
                            (data['gender'] ?? '').toString().toLowerCase();
                        final size =
                            (data['size'] ?? '').toString().toLowerCase();
                        final dateStr = data['timestamp'] != null
                            ? formatTimestamp(data['timestamp'] as Timestamp?)
                                .toLowerCase()
                            : '';

                        final queryWords = searchQuery.split(RegExp(r'\s+'));

                        bool matches = queryWords.every((word) {
                          if (word.isEmpty) return true;
                          if (word == 'male' || word == 'female') {
                            return gender == word;
                          }
                          return name.contains(word) ||
                              studentId.contains(word) ||
                              email.contains(word) ||
                              course.contains(word) ||
                              size.contains(word) ||
                              dateStr.contains(word);
                        });

                        return status != 'Approved' &&
                            status != 'Completed' &&
                            matches;
                      }).toList();

                      if (requests.isEmpty) {
                        return const Center(
                            child: Text('No pending requests.'));
                      }

                      final totalPages = rowsPerPage == -1
                          ? 1
                          : (requests.length / rowsPerPage).ceil();
                      final start = currentPage * rowsPerPage;
                      final end = rowsPerPage == -1
                          ? requests.length
                          : (start + rowsPerPage).clamp(0, requests.length);
                      final pageRequests = requests.sublist(start, end);

                      // Desktop Table
                      if (isDesktop) {
                        return Column(
                          children: [
                            Expanded(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.vertical,
                                child: Center(
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: DataTable(
                                      headingRowColor: WidgetStateProperty.all(
                                          const Color(0xFF00A86B)
                                              .withOpacity(0.1)),
                                      columnSpacing: 20,
                                      columns: const [
                                        DataColumn(
                                            label: Text('No.',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold))),
                                        DataColumn(
                                            label: Text('Name',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold))),
                                        DataColumn(
                                            label: Text('Student ID',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold))),
                                        DataColumn(
                                            label: Text('Email',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold))),
                                        DataColumn(
                                            label: Text('Course',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold))),
                                        DataColumn(
                                            label: Text('Gender',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold))),
                                        DataColumn(
                                            label: Text('Size',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold))),
                                        DataColumn(
                                            label: Text('Quantity',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold))),
                                        DataColumn(
                                            label: Text('Requested At',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold))),
                                        DataColumn(label: Text('Action')),
                                      ],
                                      rows: pageRequests.asMap().entries.map(
                                        (entry) {
                                          final index = start + entry.key + 1;
                                          final data = entry.value.data()
                                              as Map<String, dynamic>;
                                          return DataRow(
                                            cells: [
                                              DataCell(Text(index.toString())),
                                              DataCell(
                                                  Text(data['userName'] ?? '')),
                                              DataCell(Text(
                                                  data['studentId'] ?? '')),
                                              DataCell(
                                                  Text(data['email'] ?? '')),
                                              DataCell(
                                                  Text(data['course'] ?? '')),
                                              DataCell(
                                                  Text(data['gender'] ?? '')),
                                              DataCell(
                                                  Text(data['size'] ?? '')),
                                              DataCell(Text(
                                                  data['orderQuantity']
                                                          ?.toString() ??
                                                      '1')),
                                              DataCell(Text(formatTimestamp(
                                                  data['timestamp']
                                                      as Timestamp?))),
                                              DataCell(ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        const Color(
                                                            0xFF00B4FF)),
                                                onPressed: () =>
                                                    _approveRequest(
                                                        entry.value.id,
                                                        data,
                                                        context),
                                                child: const Text('Approve'),
                                              )),
                                            ],
                                          );
                                        },
                                      ).toList(),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton(
                                  onPressed: currentPage > 0
                                      ? () => setState(() => currentPage--)
                                      : null,
                                  child: const Text('Prev'),
                                ),
                                const SizedBox(width: 8),
                                for (int i = 0; i < totalPages; i++)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4),
                                    child: ElevatedButton(
                                      onPressed: () =>
                                          setState(() => currentPage = i),
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: i == currentPage
                                              ? const Color.fromARGB(
                                                  255, 136, 255, 212)
                                              : null),
                                      child: Text('${i + 1}'),
                                    ),
                                  ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: currentPage < totalPages - 1
                                      ? () => setState(() => currentPage++)
                                      : null,
                                  child: const Text('Next'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                          ],
                        );
                      }

                      // Mobile Cards
                      return ListView.builder(
                        itemCount: pageRequests.length,
                        itemBuilder: (context, index) {
                          final doc = pageRequests[index];
                          final data = doc.data() as Map<String, dynamic>;
                          return Card(
                            elevation: 3,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data['userName'] ?? 'Unknown',
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF00A86B)),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                      'Student ID: ${data['studentId'] ?? ''}'),
                                  Text('Email: ${data['email'] ?? ''}'),
                                  Text('Course: ${data['course'] ?? ''}'),
                                  Text('Gender: ${data['gender'] ?? ''}'),
                                  Text('Size: ${data['size'] ?? ''}'),
                                  Text(
                                      'Quantity: ${data['orderQuantity']?.toString() ?? '1'}'),
                                  Text(
                                      'Requested At: ${formatTimestamp(data['timestamp'] as Timestamp?)}'),
                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xFF00B4FF)),
                                      onPressed: () => _approveRequest(
                                          doc.id, data, context),
                                      child: const Text('Approve'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ============================
/// Approved Orders Tab with Search
/// ============================
class ApprovedOrdersListPage extends StatefulWidget {
  const ApprovedOrdersListPage({super.key});

  @override
  State<ApprovedOrdersListPage> createState() => _ApprovedOrdersListPageState();
}

class _ApprovedOrdersListPageState extends State<ApprovedOrdersListPage> {
  String searchQuery = '';
  int rowsPerPage = 10;
  int currentPage = 0;

  // ✅ Format timestamp to "MMM/dd/yyyy hh:mm a"
  String formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'N/A';
    final date = timestamp.toDate();
    return DateFormat('MMM/dd/yyyy hh:mm a')
        .format(date); // Oct/15/2025 03:45 PM
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 700;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  "Approved Orders",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00A86B),
                  ),
                ),
                const SizedBox(height: 16),

                // ✅ QR Button
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminQrConfirmationPage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('QR Confirmation'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00A86B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 20),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 🔍 Search + Rows per page
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: isDesktop ? 250 : 180,
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search',
                          prefixIcon: const Icon(Icons.search,
                              color: Color(0xFF00B4FF)),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            searchQuery = value.toLowerCase();
                            currentPage = 0;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black12),
                      ),
                      child: DropdownButton<int>(
                        value: rowsPerPage,
                        underline: const SizedBox(),
                        items: const [
                          DropdownMenuItem(value: 10, child: Text("10")),
                          DropdownMenuItem(value: 50, child: Text("50")),
                          DropdownMenuItem(value: 100, child: Text("100")),
                          DropdownMenuItem(value: -1, child: Text("ALL")),
                        ],
                        onChanged: (value) {
                          setState(() {
                            rowsPerPage = value!;
                            currentPage = 0;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 🔹 Orders List / Table / Mobile List
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('uniform_requests')
                        .orderBy('approvedAt', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator(
                                color: Color(0xFF00B4FF)));
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(
                            child: Text('No approved orders found.'));
                      }

                      final allOrders = snapshot.data!.docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final status = data['status'] ?? '';

                        // search filter
                        final name =
                            (data['userName'] ?? '').toString().toLowerCase();
                        final studentId =
                            (data['studentId'] ?? '').toString().toLowerCase();
                        final email =
                            (data['email'] ?? '').toString().toLowerCase();
                        final course =
                            (data['course'] ?? '').toString().toLowerCase();
                        final gender =
                            (data['gender'] ?? '').toString().toLowerCase();
                        final size =
                            (data['size'] ?? '').toString().toLowerCase();
                        final dateStr = data['approvedAt'] != null
                            ? formatTimestamp(data['approvedAt'] as Timestamp)
                                .toLowerCase()
                            : '';

                        final queryWords = searchQuery.split(RegExp(r'\s+'));

                        return status == 'Approved' &&
                            queryWords.every((word) {
                              if (word.isEmpty) return true;
                              if (word == 'male' || word == 'female') {
                                return gender == word;
                              }
                              return name.contains(word) ||
                                  studentId.contains(word) ||
                                  email.contains(word) ||
                                  course.contains(word) ||
                                  size.contains(word) ||
                                  dateStr.contains(word);
                            });
                      }).toList();

                      // Pagination
                      final totalPages = rowsPerPage == -1
                          ? 1
                          : (allOrders.length / rowsPerPage).ceil();
                      final start = currentPage * rowsPerPage;
                      final end = rowsPerPage == -1
                          ? allOrders.length
                          : (start + rowsPerPage).clamp(0, allOrders.length);
                      final pageOrders = allOrders.sublist(start, end);

                      // Desktop Table
                      if (isDesktop) {
                        return Column(
                          children: [
                            Expanded(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.vertical,
                                child: Center(
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: DataTable(
                                      headingRowColor: WidgetStateProperty.all(
                                          const Color(0xFF00A86B)
                                              .withOpacity(0.1)),
                                      columnSpacing: 20,
                                      columns: const [
                                        DataColumn(
                                            label: Text('No.',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold))),
                                        DataColumn(
                                            label: Text('Name',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold))),
                                        DataColumn(
                                            label: Text('Student ID',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold))),
                                        DataColumn(
                                            label: Text('Email',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold))),
                                        DataColumn(
                                            label: Text('Course',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold))),
                                        DataColumn(
                                            label: Text('Sex Uniform',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold))),
                                        DataColumn(
                                            label: Text('Size',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold))),
                                        DataColumn(
                                            label: Text('Quantity',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold))),
                                        DataColumn(
                                            label: Text('Approved At',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold))),
                                      ],
                                      rows: pageOrders
                                          .asMap()
                                          .entries
                                          .map((entry) {
                                        final index = start + entry.key + 1;
                                        final data = entry.value.data()
                                            as Map<String, dynamic>;
                                        return DataRow(
                                          cells: [
                                            DataCell(Text(index.toString())),
                                            DataCell(
                                                Text(data['userName'] ?? '')),
                                            DataCell(
                                                Text(data['studentId'] ?? '')),
                                            DataCell(Text(data['email'] ?? '')),
                                            DataCell(
                                                Text(data['course'] ?? '')),
                                            DataCell(
                                                Text(data['gender'] ?? '')),
                                            DataCell(Text(data['size'] ?? '')),
                                            DataCell(Text(data['orderQuantity']
                                                    ?.toString() ??
                                                '1')),
                                            DataCell(Text(formatTimestamp(
                                                data['approvedAt']
                                                    as Timestamp))),
                                          ],
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Pagination buttons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton(
                                  onPressed: currentPage > 0
                                      ? () => setState(() => currentPage--)
                                      : null,
                                  child: const Text('Prev'),
                                ),
                                const SizedBox(width: 8),
                                for (int i = 0; i < totalPages; i++)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4),
                                    child: ElevatedButton(
                                      onPressed: () =>
                                          setState(() => currentPage = i),
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: i == currentPage
                                              ? const Color.fromARGB(
                                                  255, 118, 255, 205)
                                              : null),
                                      child: Text('${i + 1}'),
                                    ),
                                  ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: currentPage < totalPages - 1
                                      ? () => setState(() => currentPage++)
                                      : null,
                                  child: const Text('Next'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                          ],
                        );
                      }

                      // Mobile view
                      return ListView.builder(
                        itemCount: pageOrders.length,
                        itemBuilder: (context, index) {
                          final data =
                              pageOrders[index].data() as Map<String, dynamic>;
                          return Card(
                            elevation: 3,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${data['userName'] ?? 'Unknown'} (${data['studentId'] ?? ''})',
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF00A86B)),
                                  ),
                                  const SizedBox(height: 6),
                                  Text('Email: ${data['email'] ?? ''}'),
                                  Text('Course: ${data['course'] ?? ''}'),
                                  Text('Gender: ${data['gender'] ?? ''}'),
                                  Text('Size: ${data['size'] ?? ''}'),
                                  Text(
                                      'Quantity: ${data['orderQuantity']?.toString() ?? '1'}'),
                                  Text(
                                      'Approved At: ${formatTimestamp(data['approvedAt'] as Timestamp)}'),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
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
  int rowsPerPage = 10; // default 10 rows
  int currentPage = 0; // current page index

  // 🔹 Helper function to format timestamp
  String formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'N/A';
    final date = timestamp.toDate();
    return DateFormat('MMM/dd/yyyy hh:mm a').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 700;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  "Completed Orders",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00A86B),
                  ),
                ),
                const SizedBox(height: 16),

                // 🔍 Search + Rows Per Page (Filter)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: isDesktop ? 250 : 180,
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search',
                          prefixIcon: const Icon(Icons.search,
                              color: Color(0xFF00B4FF)),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            searchQuery = value.toLowerCase();
                            currentPage = 0;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black12),
                      ),
                      child: DropdownButton<int>(
                        value: rowsPerPage,
                        underline: const SizedBox(),
                        items: const [
                          DropdownMenuItem(value: 10, child: Text("10")),
                          DropdownMenuItem(value: 50, child: Text("50")),
                          DropdownMenuItem(value: 100, child: Text("100")),
                          DropdownMenuItem(value: -1, child: Text("ALL")),
                        ],
                        onChanged: (value) {
                          setState(() {
                            rowsPerPage = value!;
                            currentPage = 0;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 🔹 Orders List
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('uniform_requests')
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator(
                                color: Color(0xFF00B4FF)));
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(
                            child: Text('No completed orders found.'));
                      }

                      final allOrders = snapshot.data!.docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final status = data['status'] ?? '';

                        // Search filter
                        final name = (data['userName'] ?? '')
                            .toString()
                            .toLowerCase()
                            .trim();
                        final studentId = (data['studentId'] ?? '')
                            .toString()
                            .toLowerCase()
                            .trim();
                        final email =
                            (data['email'] ?? '').toString().toLowerCase();
                        final course =
                            (data['course'] ?? '').toString().toLowerCase();
                        final gender =
                            (data['gender'] ?? '').toString().toLowerCase();
                        final size =
                            (data['size'] ?? '').toString().toLowerCase();
                        final dateStr = data['timestamp'] != null
                            ? formatTimestamp(data['timestamp'] as Timestamp)
                                .toLowerCase()
                            : '';

                        final queryWords =
                            searchQuery.split(RegExp(r'\s+')).toList();

                        return status == 'Completed' &&
                            queryWords.every((word) {
                              if (word.isEmpty) return true;
                              if (word == 'male' || word == 'female') {
                                return gender == word;
                              }
                              return name.contains(word) ||
                                  studentId.contains(word) ||
                                  email.contains(word) ||
                                  course.contains(word) ||
                                  size.contains(word) ||
                                  dateStr.contains(word);
                            });
                      }).toList();

                      // Pagination calculation
                      final totalPages = rowsPerPage == -1
                          ? 1
                          : (allOrders.length / rowsPerPage).ceil();
                      final start = currentPage * rowsPerPage;
                      final end = rowsPerPage == -1
                          ? allOrders.length
                          : (start + rowsPerPage).clamp(0, allOrders.length);
                      final pageOrders = allOrders.sublist(start, end);

                      // Desktop: DataTable
                      if (isDesktop) {
                        return Column(
                          children: [
                            Expanded(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.vertical,
                                child: Center(
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: DataTable(
                                      headingRowColor: WidgetStateProperty.all(
                                          const Color(0xFF00A86B)
                                              .withOpacity(0.1)),
                                      columnSpacing: 20,
                                      columns: const [
                                        DataColumn(
                                            label: Text('No.',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold))),
                                        DataColumn(
                                            label: Text('Name',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold))),
                                        DataColumn(
                                            label: Text('Student ID',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold))),
                                        DataColumn(
                                            label: Text('Email',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold))),
                                        DataColumn(
                                            label: Text('Course',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold))),
                                        DataColumn(
                                            label: Text('Sex Uniform',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold))),
                                        DataColumn(
                                            label: Text('Size',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold))),
                                        DataColumn(
                                            label: Text('Quantity',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold))),
                                        DataColumn(
                                            label: Text('Completed At',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold))),
                                      ],
                                      rows: pageOrders
                                          .asMap()
                                          .entries
                                          .map((entry) {
                                        final index = start + entry.key + 1;
                                        final data = entry.value.data()
                                            as Map<String, dynamic>;
                                        return DataRow(
                                          cells: [
                                            DataCell(Text(index.toString())),
                                            DataCell(
                                                Text(data['userName'] ?? '')),
                                            DataCell(
                                                Text(data['studentId'] ?? '')),
                                            DataCell(Text(data['email'] ?? '')),
                                            DataCell(
                                                Text(data['course'] ?? '')),
                                            DataCell(
                                                Text(data['gender'] ?? '')),
                                            DataCell(Text(data['size'] ?? '')),
                                            DataCell(Text(data['orderQuantity']
                                                    ?.toString() ??
                                                '1')),
                                            DataCell(Text(formatTimestamp(
                                                data['timestamp']
                                                    as Timestamp?))),
                                          ],
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // 🔹 Pagination Buttons
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton(
                                  onPressed: currentPage > 0
                                      ? () => setState(() => currentPage--)
                                      : null,
                                  child: const Text('Prev'),
                                ),
                                const SizedBox(width: 8),
                                for (int i = 0; i < totalPages; i++)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4),
                                    child: ElevatedButton(
                                      onPressed: () =>
                                          setState(() => currentPage = i),
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: i == currentPage
                                              ? const Color.fromARGB(
                                                  255, 93, 255, 196)
                                              : null),
                                      child: Text('${i + 1}'),
                                    ),
                                  ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: currentPage < totalPages - 1
                                      ? () => setState(() => currentPage++)
                                      : null,
                                  child: const Text('Next'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                          ],
                        );
                      }

                      // Mobile view (no DataTable)
                      return ListView.builder(
                        itemCount: pageOrders.length,
                        itemBuilder: (context, index) {
                          final data =
                              pageOrders[index].data() as Map<String, dynamic>;
                          return Card(
                            elevation: 3,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${data['userName'] ?? 'Unknown'} (${data['studentId'] ?? ''})',
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF00A86B)),
                                  ),
                                  const SizedBox(height: 6),
                                  Text('Email: ${data['email'] ?? ''}'),
                                  Text('Course: ${data['course'] ?? ''}'),
                                  Text('Gender: ${data['gender'] ?? ''}'),
                                  Text('Size: ${data['size'] ?? ''}'),
                                  Text(
                                      'Quantity: ${data['orderQuantity']?.toString() ?? '1'}'),
                                  Text(
                                      'Completed At: ${formatTimestamp(data['timestamp'] as Timestamp?)}'),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

///Inventory Management Page
class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  // ✅ Get all uniforms by course
  Stream<List<Uniform>> getUniformsByCourse(String course) {
    return FirebaseFirestore.instance
        .collection('uniforms')
        .where('course', isEqualTo: course)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Uniform.fromMap(doc.data(), doc.id))
            .toList());
  }

  // ✅ Update stock and add history record if stock increases
  Future<void> _updateStockIn(
      BuildContext context, Uniform uniform, int newQuantity) async {
    try {
      final docRef =
          FirebaseFirestore.instance.collection('uniforms').doc(uniform.id);
      final docSnap = await docRef.get();
      if (!docSnap.exists) return;

      final data = docSnap.data()!;
      final oldQuantity = data['quantity'] ?? 0;

      // 🔹 If stock increased
      if (newQuantity > oldQuantity) {
        final addedQuantity = newQuantity - oldQuantity;

        // ✅ Update main stock quantity
        await docRef.update({
          'quantity': newQuantity,
          'lastEdited': FieldValue.serverTimestamp(),
        });

        // ✅ Add stock-in record to history collection
        await FirebaseFirestore.instance.collection('inventory_history').add({
          'course': data['course'] ?? '',
          'gender': data['gender'] ?? '',
          'size': data['size'] ?? '',
          'stockIn': addedQuantity,
          'stockOut': 0,
          'remaining': newQuantity,
          'date': Timestamp.now(), // use Timestamp.now() for consistency
        });
      } else {
        // 🔹 Just update quantity if stock didn’t increase
        await docRef.update({
          'quantity': newQuantity,
          'lastEdited': FieldValue.serverTimestamp(),
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Stock updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error updating stock: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update stock: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ✅ Open form for add/edit uniform
  void _openForm([Uniform? uniform]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => UniformFormPage(uniform: uniform)),
    );

    if (result != null) {
      if (uniform != null && result is int) {
        // Edited existing uniform → update stock
        await _updateStockIn(context, uniform, result); // ✅ use result
      } else if (uniform == null && result is Uniform) {
        // Added new uniform → save and record in history
        final newUniform = result;
        final docRef = FirebaseFirestore.instance
            .collection('uniforms')
            .doc(newUniform.id);
        await docRef.set(newUniform.toMap());

        await FirebaseFirestore.instance.collection('inventory_history').add({
          'course': newUniform.course,
          'gender': newUniform.gender,
          'size': newUniform.size,
          'stockIn': newUniform.quantity,
          'stockOut': 0,
          'remaining': newUniform.quantity,
          'date': FieldValue.serverTimestamp(),
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final courses = ['BSCS', 'ABCOM', 'BSCRIM'];
    final isWide = MediaQuery.of(context).size.width > 800;

    return DefaultTabController(
      length: courses.length,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F9FC),
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: const Color(0xFF00B36B),
          title: const Text(
            'Inventory Management',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            tabs: const [
              Tab(text: 'BSCS'),
              Tab(text: 'ABCOM'),
              Tab(text: 'BSCRIM'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: courses
              .map((course) => _buildCourseInventory(course, isWide))
              .toList(),
        ),
      ),
    );
  }

  // ✅ Builds each course inventory tab
  Widget _buildCourseInventory(String course, bool isWide) {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isWide ? 900 : double.infinity),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 10),
                Expanded(
                  child: ScrollConfiguration(
                    behavior: const ScrollBehavior().copyWith(
                      scrollbars: true,
                      dragDevices: {
                        PointerDeviceKind.touch,
                        PointerDeviceKind.mouse,
                      },
                    ),
                    child: StreamBuilder<List<Uniform>>(
                      stream: getUniformsByCourse(course),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Center(
                            child: Text(
                              'No uniforms found for this course.',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 16),
                            ),
                          );
                        }

                        final uniforms = snapshot.data!;
                        final groupedBySize = <String, List<Uniform>>{};
                        for (final uniform in uniforms) {
                          groupedBySize.putIfAbsent(uniform.size, () => []);
                          groupedBySize[uniform.size]!.add(uniform);
                        }

                        return ListView(
                          children: groupedBySize.entries.map((entry) {
                            final size = entry.key;
                            final uniforms = entry.value;
                            final totalQty = uniforms.fold<int>(
                              0,
                              (sum, u) => sum + (u.quantity ?? 0),
                            );

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 3,
                              child: ExpansionTile(
                                title: Text(
                                  'Size: $size (Total: $totalQty)',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF004D40),
                                  ),
                                ),
                                children: uniforms.map((u) {
                                  return ListTile(
                                    title: Text(
                                      u.gender,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: Text('Quantity: ${u.quantity}'),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.edit,
                                          color: Colors.orange),
                                      onPressed: () => _openForm(u),
                                    ),
                                  );
                                }).toList(),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HistoryStockReportTab extends StatelessWidget {
  const HistoryStockReportTab({super.key});

  String formatDate(dynamic ts) {
    if (ts == null) return '';
    try {
      final dt =
          (ts is Timestamp) ? ts.toDate() : DateTime.parse(ts.toString());
      return DateFormat('MMM dd, yyyy hh:mm a').format(dt);
    } catch (e) {
      return ts.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'History Stock Report',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF00A86B),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('inventory_history')
                    .orderBy('date', descending: true)
                    .snapshots(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(
                      color: Color(0xFF00B4FF),
                    ));
                  }

                  final docs = snap.data?.docs ?? [];

                  if (docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'No data',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    );
                  }

                  final rows = docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final course = (data['course'] ?? '').toString();
                    final gender = (data['gender'] ?? '').toString();
                    final size = (data['size'] ?? '').toString();
                    final stockIn = (data['stockIn'] ?? 0).toString();
                    final stockOut = (data['stockOut'] ?? 0).toString();
                    final remaining = ((data['remaining'] != null)
                            ? data['remaining'].toString()
                            : (int.tryParse(stockIn) ?? 0) -
                                (int.tryParse(stockOut) ?? 0))
                        .toString();
                    final dateStr = formatDate(data['date']);

                    return DataRow(cells: [
                      DataCell(Text(course)),
                      DataCell(Text(gender)),
                      DataCell(Text(size)),
                      DataCell(Text(stockIn)),
                      DataCell(Text(stockOut)),
                      DataCell(Text(remaining)),
                      DataCell(Text(dateStr)),
                    ]);
                  }).toList();

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Course')),
                        DataColumn(label: Text('Sex')),
                        DataColumn(label: Text('Size')),
                        DataColumn(label: Text('Stock In')),
                        DataColumn(label: Text('Stock Out')),
                        DataColumn(label: Text('Remaining Stock')),
                        DataColumn(label: Text('Date')),
                      ],
                      rows: rows,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
