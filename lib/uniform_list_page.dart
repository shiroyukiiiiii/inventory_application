import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/uniform.dart';
import 'admin_qr_confirmation.dart';
import 'services/emailjs_service.dart';
import 'package:intl/intl.dart';
import 'package:flutter/gestures.dart';
import 'package:inventory_application/services/lowstockemail.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'dart:typed_data';
import 'package:excel/excel.dart' as exl;
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';

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
    _tabController = TabController(length: 5, vsync: this);
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
            CancelledOrdersListPage(),
            InventoryPage(),
          ],
        );
    }
  }

  void _showHistoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text(
            'Edit History',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('inventory_history')
                  .orderBy('date', descending: true)
                  .limit(20) // limit to recent 20 edits
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No history records found.'));
                }

                final history = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final data = history[index].data() as Map<String, dynamic>;
                    final course = data['course'] ?? '';
                    final gender = data['gender'] ?? '';
                    final size = data['size'] ?? '';
                    final stockIn = data['stockIn'] ?? 0;
                    final stockOut = data['stockOut'] ?? 0;
                    final remaining = data['remaining'] ?? 0;
                    final remarks = data['remarks'] ?? '';
                    final date = (data['date'] as Timestamp?)?.toDate();

                    return ListTile(
                      leading: Icon(
                        stockIn > 0
                            ? Icons.add_circle_outline
                            : Icons.remove_circle_outline,
                        color: stockIn > 0 ? Colors.green : Colors.red,
                      ),
                      title: Text('$course - $gender - $size'),
                      subtitle: Text(
                        'In: $stockIn | Out: $stockOut | Remaining: $remaining\nRemarks: $remarks',
                      ),
                      trailing: Text(
                        date != null
                            ? '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}'
                            : '',
                        style: const TextStyle(fontSize: 12),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
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

              // 🆕 NEW — Cancelled Orders Drawer Option
              ListTile(
                leading: const Icon(Icons.cancel, color: Colors.redAccent),
                title: const Text('Cancelled Orders'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedPage = 'tabs';
                    _tabController.index = 3; // match Cancelled tab index
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
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            tooltip: 'View Edit History',
            onPressed: () {
              _showHistoryDialog(context);
            },
          ),
        ],
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
                  Tab(icon: Icon(Icons.cancel), text: 'Cancelled'),
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
    final historyRef =
        FirebaseFirestore.instance.collection('inventory_history');
    String message = '';

    if (widget.uniform != null) {
      // 🔹 Editing existing uniform
      final docRef = uniformsRef.doc(widget.uniform!.id);
      final oldDoc = await docRef.get();
      final oldData = oldDoc.data() ?? {};
      final oldQuantity = oldData['quantity'] ?? 0;
      final quantityChange = _quantity - oldQuantity;

      await docRef.update({
        'course': _course,
        'gender': _gender,
        'size': _size,
        'quantity': _quantity,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // ✅ Record edit in history
      await historyRef.add({
        'course': _course,
        'gender': _gender,
        'size': _size,
        'stockIn': quantityChange > 0 ? quantityChange : 0,
        'stockOut': quantityChange < 0 ? quantityChange.abs() : 0,
        'remaining': _quantity,
        'remarks': quantityChange == 0
            ? 'Stock edited (no quantity change)'
            : (quantityChange > 0 ? 'Stock increased' : 'Stock decreased'),
        'date': Timestamp.now(),
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
        final oldQuantity = existingDoc['quantity'] ?? 0;
        final newQuantity = oldQuantity + _quantity;

        await uniformsRef.doc(existingDoc.id).update({
          'quantity': newQuantity,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // ✅ Record stock-in in history
        await historyRef.add({
          'course': _course,
          'gender': _gender,
          'size': _size,
          'stockIn': _quantity,
          'stockOut': 0,
          'remaining': newQuantity,
          'remarks': 'Stock increased (new batch added)',
          'date': Timestamp.now(),
        });

        message = 'Stock updated successfully!';
      } else {
        // 🔹 New uniform entry
        await uniformsRef.add({
          'course': _course,
          'gender': _gender,
          'size': _size,
          'quantity': _quantity,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // ✅ Record creation in history
        await historyRef.add({
          'course': _course,
          'gender': _gender,
          'size': _size,
          'stockIn': _quantity,
          'stockOut': 0,
          'remaining': _quantity,
          'remarks': 'New uniform stock added',
          'date': Timestamp.now(),
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

      int updatedStock = 0;

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

        updatedStock = currentStock - (data['orderQuantity'] ?? 1) as int;
        transaction.update(uniformDoc, {'quantity': updatedStock});
        transaction.update(requestRef, {
          'status': 'Approved',
          'approvedAt': FieldValue.serverTimestamp(),
        });
      });

// ✅ Notify the student that their request was approved
      await EmailJsService.sendApprovalEmail(
        toEmail: data['email'] ?? '',
        toName: data['userName'] ?? '',
        studentNumber: data['studentId'] ?? '',
        studentName: data['userName'] ?? '',
        gender: data['gender'] ?? '',
        course: data['course'] ?? '',
        size: data['size'] ?? '',
        qrCode: data['qrCode'] ?? '',
        orderQuantity: data['orderQuantity'] ?? 1,
      );

// 🚨 NEW: If stock is low (e.g., 5 or below), notify the admin
      if (updatedStock <= 5) {
        await LowStockEmailService.sendLowStockAlert(
          course: course,
          gender: gender,
          size: size,
          remainingStock: updatedStock,
          toEmail:
              'ninipiegaming.karl@gmail.com', // ⚙️ Replace with actual admin email
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✅ Approved $course - $gender - $size. Stock deducted and email sent!'
            '${updatedStock <= 5 ? ' (Low stock alert sent to admin!)' : ''}',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error approving request: $e')),
      );
    }
  }

  Future<void> _confirmApproval(
    String id,
    Map<String, dynamic> data,
    BuildContext context,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // user must choose explicitly
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Colors.white,
          titlePadding: const EdgeInsets.only(top: 20),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          title: Row(
            children: const [
              Icon(Icons.check_circle_outline,
                  color: Color(0xFF00A86B), size: 28),
              SizedBox(width: 8),
              Text(
                'Approve Request',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00A86B),
                ),
              ),
            ],
          ),
          content: const Text(
            'Are you sure you want to approve this uniform request? '
            'This will deduct stock and notify the student via email.',
            style: TextStyle(fontSize: 15),
          ),
          actionsPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[700],
              ),
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.check, size: 18, color: Colors.white),
              label: const Text(
                'Approve',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00A86B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _approveRequest(id, data, context);
    }
  }

  /// Cancel Request

  Future<void> _cancelRequest(
    String id,
    Map<String, dynamic> data,
    BuildContext context,
  ) async {
    final firestore = FirebaseFirestore.instance;

    try {
      final requestRef = firestore.collection('uniform_requests').doc(id);

      // Check current status first
      final requestSnap = await requestRef.get();
      final currentStatus =
          (requestSnap.data()?['status'] ?? 'Pending').toString();

      if (currentStatus == 'Cancelled') {
        throw Exception('Request already cancelled.');
      }
      if (currentStatus == 'Approved' || currentStatus == 'Completed') {
        throw Exception('Approved or completed requests cannot be cancelled.');
      }

      // Update status to "Cancelled"
      await requestRef.update({
        'status': 'Cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🚫 Request has been marked as cancelled.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error cancelling request: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _confirmCancellation(
    String id,
    Map<String, dynamic> data,
    BuildContext context,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: Colors.white,
          titlePadding: const EdgeInsets.only(top: 20),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          title: Row(
            children: const [
              Icon(Icons.cancel_outlined, color: Colors.red, size: 28),
              SizedBox(width: 8),
              Text(
                'Cancel Request',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          content: const Text(
            'Are you sure you want to cancel this uniform request? '
            'This action cannot be undone.',
            style: TextStyle(fontSize: 15),
          ),
          actionsPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.cancel, color: Colors.white, size: 18),
              label: const Text('Yes, Cancel'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _cancelRequest(id, data, context);
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
                            status != 'Cancelled' &&
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
                                              DataCell(
                                                Row(
                                                  children: [
                                                    ElevatedButton(
                                                      style: ElevatedButton
                                                          .styleFrom(
                                                        backgroundColor:
                                                            const Color(
                                                                0xFF00B4FF),
                                                      ),
                                                      onPressed: () =>
                                                          _confirmApproval(
                                                              entry.value.id,
                                                              data,
                                                              context),
                                                      child:
                                                          const Text('Approve'),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    ElevatedButton(
                                                      style: ElevatedButton
                                                          .styleFrom(
                                                        backgroundColor:
                                                            Colors.redAccent,
                                                      ),
                                                      onPressed: () =>
                                                          _confirmCancellation(
                                                              entry.value.id,
                                                              data,
                                                              context),
                                                      child:
                                                          const Text('Cancel'),
                                                    ),
                                                  ],
                                                ),
                                              ),
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

/// ================================ ///
/// Cancelled Orders Tab with Search ///
/// =============================== ///

class CancelledOrdersListPage extends StatefulWidget {
  const CancelledOrdersListPage({super.key});

  @override
  State<CancelledOrdersListPage> createState() =>
      _CancelledOrdersListPageState();
}

class _CancelledOrdersListPageState extends State<CancelledOrdersListPage> {
  String searchQuery = '';
  int rowsPerPage = 10;
  int currentPage = 0;

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
                  "Cancelled Orders",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF4D4D), // 🔴 Red for Cancelled Orders
                  ),
                ),
                const SizedBox(height: 16),

                // 🔍 Search + Rows Per Page
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: isDesktop ? 250 : 180,
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search',
                          prefixIcon: const Icon(Icons.search,
                              color: Color(0xFFFF4D4D)),
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
                                color: Color(0xFFFF4D4D)));
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(
                            child: Text('No cancelled orders found.'));
                      }

                      final allOrders = snapshot.data!.docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final status = data['status'] ?? '';

                        // Search filter
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
                            ? formatTimestamp(data['timestamp'] as Timestamp)
                                .toLowerCase()
                            : '';

                        final queryWords =
                            searchQuery.split(RegExp(r'\s+')).toList();

                        return status == 'Cancelled' &&
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

                      final totalPages = rowsPerPage == -1
                          ? 1
                          : (allOrders.length / rowsPerPage).ceil();
                      final start = currentPage * rowsPerPage;
                      final end = rowsPerPage == -1
                          ? allOrders.length
                          : (start + rowsPerPage).clamp(0, allOrders.length);
                      final pageOrders = allOrders.sublist(start, end);

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
                                          const Color(0xFFFF4D4D)
                                              .withOpacity(0.1)),
                                      columnSpacing: 20,
                                      columns: const [
                                        DataColumn(label: Text('No.')),
                                        DataColumn(label: Text('Name')),
                                        DataColumn(label: Text('Student ID')),
                                        DataColumn(label: Text('Email')),
                                        DataColumn(label: Text('Course')),
                                        DataColumn(label: Text('Sex Uniform')),
                                        DataColumn(label: Text('Size')),
                                        DataColumn(label: Text('Quantity')),
                                        DataColumn(label: Text('Cancelled At')),
                                      ],
                                      rows: pageOrders
                                          .asMap()
                                          .entries
                                          .map((entry) {
                                        final index = start + entry.key + 1;
                                        final data = entry.value.data()
                                            as Map<String, dynamic>;
                                        return DataRow(
                                          color: WidgetStateProperty.all(
                                              Colors.red.withOpacity(0.05)),
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
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton(
                                  onPressed: currentPage > 0
                                      ? () => setState(() => currentPage--)
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFFF4D4D)),
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
                                              ? const Color(0xFFFFA0A0)
                                              : null),
                                      child: Text('${i + 1}'),
                                    ),
                                  ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: currentPage < totalPages - 1
                                      ? () => setState(() => currentPage++)
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFFF4D4D)),
                                  child: const Text('Next'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                          ],
                        );
                      }

                      // 📱 Mobile view
                      return ListView.builder(
                        itemCount: pageOrders.length,
                        itemBuilder: (context, index) {
                          final data =
                              pageOrders[index].data() as Map<String, dynamic>;
                          return Card(
                            elevation: 3,
                            color: Colors.red[50],
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
                                        color: Color(0xFFFF4D4D)),
                                  ),
                                  const SizedBox(height: 6),
                                  Text('Email: ${data['email'] ?? ''}'),
                                  Text('Course: ${data['course'] ?? ''}'),
                                  Text('Gender: ${data['gender'] ?? ''}'),
                                  Text('Size: ${data['size'] ?? ''}'),
                                  Text(
                                      'Quantity: ${data['orderQuantity']?.toString() ?? '1'}'),
                                  Text(
                                      'Cancelled At: ${formatTimestamp(data['timestamp'] as Timestamp?)}'),
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
    _tabController = TabController(length: 5, vsync: this);
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
    BuildContext context,
    Uniform uniform,
    int newQuantity,
  ) async {
    try {
      final docRef =
          FirebaseFirestore.instance.collection('uniforms').doc(uniform.id);
      final docSnap = await docRef.get();

      if (!docSnap.exists) return;

      final data = docSnap.data()!;
      final oldQuantity = data['quantity'] ?? 0;

      // Calculate the change
      final quantityChange = newQuantity - oldQuantity;

      // ✅ Always update the stock
      await docRef.update({
        'quantity': newQuantity,
        'lastEdited': FieldValue.serverTimestamp(),
      });

      // ✅ Always add a history record
      await FirebaseFirestore.instance.collection('inventory_history').add({
        'course': data['course'] ?? '',
        'gender': data['gender'] ?? '',
        'size': data['size'] ?? '',
        'stockIn': quantityChange > 0 ? quantityChange : 0,
        'stockOut': quantityChange < 0 ? quantityChange.abs() : 0,
        'remaining': newQuantity,
        'editedBy': 'Admin', // optional: add current user or editor name
        'remarks': quantityChange == 0
            ? 'Stock edited (no change in quantity)'
            : (quantityChange > 0 ? 'Stock increased' : 'Stock decreased'),
        'date': Timestamp.now(),
      });

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
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white,
            labelStyle: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            tabs: [
              Tab(text: 'BSCS'),
              Tab(text: 'ABCOM'),
              Tab(text: 'BSCRIM'),
            ],
          ),
        ),
        body: TabBarView(
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

class HistoryStockReportTab extends StatefulWidget {
  const HistoryStockReportTab({super.key});

  @override
  State<HistoryStockReportTab> createState() => _HistoryStockReportTabState();
}

class _HistoryStockReportTabState extends State<HistoryStockReportTab> {
  String? selectedMonth;
  final months =
      List.generate(12, (i) => DateFormat('MMMM').format(DateTime(0, i + 1)));

  String formatDate(dynamic ts) {
    if (ts == null) return '';
    try {
      final dt =
          (ts is Timestamp) ? ts.toDate() : DateTime.tryParse(ts.toString());
      if (dt == null) return '';
      return DateFormat('MMM dd, yyyy hh:mm a').format(dt);
    } catch (_) {
      return ts.toString();
    }
  }

  bool isSameMonth(dynamic ts) {
    if (selectedMonth == null) return true;
    if (ts == null) return false;
    DateTime? date =
        (ts is Timestamp) ? ts.toDate() : DateTime.tryParse(ts.toString());
    if (date == null) return false;
    return DateFormat('MMMM').format(date) == selectedMonth;
  }

  Future<List<QueryDocumentSnapshot>> getFilteredDocs() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('inventory_history')
        .orderBy('date', descending: true)
        .get();
    return snapshot.docs.where((d) => isSameMonth(d['date'])).toList();
  }

  Future<void> exportToPDF() async {
    try {
      final docs = await getFilteredDocs();
      if (docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No data to export!')),
        );
        return;
      }

      final pdf = pw.Document();
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (context) => [
            pw.Center(
              child: pw.Text(
                'History Stock Report of School Uniforms - ${selectedMonth ?? "All Months"}',
                style:
                    pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.SizedBox(height: 10),
            pw.TableHelper.fromTextArray(
              headers: const [
                'Course',
                'Sex',
                'Size',
                'Stock In',
                'Stock Out',
                'Remaining',
                'Date'
              ],
              data: docs.map((doc) {
                final d = doc.data() as Map<String, dynamic>;
                return [
                  d['course'] ?? '',
                  d['gender'] ?? '',
                  d['size'] ?? '',
                  d['stockIn']?.toString() ?? '0',
                  d['stockOut']?.toString() ?? '0',
                  d['remaining']?.toString() ?? '0',
                  formatDate(d['date']),
                ];
              }).toList(),
              cellAlignment: pw.Alignment.center,
              cellStyle: const pw.TextStyle(fontSize: 10),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),
      );

      final pdfBytes = await pdf.save();
      final fileName =
          'history_report_${selectedMonth?.toLowerCase() ?? "all"}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';

      await FileSaver.instance.saveFile(
        name: fileName,
        bytes: Uint8List.fromList(pdfBytes),
        ext: "pdf",
        mimeType: MimeType.pdf,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF saved as $fileName')),
      );
    } catch (e, stack) {
      debugPrint('PDF export error: $e');
      debugPrint('Stack: $stack');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to export PDF: $e')),
      );
    }
  }

  Future<void> exportToExcel() async {
    try {
      final docs = await getFilteredDocs();
      if (docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No data to export!')),
        );
        return;
      }

      final excel = exl.Excel.createExcel();
      final sheet = excel['Sheet1'];

      final headers = [
        'Course',
        'Sex',
        'Size',
        'Stock In',
        'Stock Out',
        'Remaining',
        'Date'
      ];
      sheet.appendRow(headers);

      for (var doc in docs) {
        final d = doc.data() as Map<String, dynamic>;
        sheet.appendRow([
          d['course'] ?? '',
          d['gender'] ?? '',
          d['size'] ?? '',
          d['stockIn']?.toString() ?? '0',
          d['stockOut']?.toString() ?? '0',
          d['remaining']?.toString() ?? '0',
          formatDate(d['date']),
        ]);
      }

      final excelBytes = excel.encode();
      if (excelBytes == null || excelBytes.isEmpty) {
        throw Exception("Excel encoding failed.");
      }

      final fileName = 'History_Stock_Report_${selectedMonth ?? "All"}.xlsx';

      if (kIsWeb) {
        await FileSaver.instance.saveFile(
          name: fileName,
          bytes: Uint8List.fromList(excelBytes),
          ext: 'xlsx',
          mimeType: MimeType.microsoftExcel,
        );
      } else {
        final dir = await getApplicationDocumentsDirectory();
        final path = '${dir.path}/$fileName';
        final file = File(path);
        await file.writeAsBytes(excelBytes);
        await OpenFile.open(file.path);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exported successfully: $fileName')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to export Excel: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 800;

    return Center(
      child: Container(
        width: isWide ? 1000 : double.infinity,
        padding: EdgeInsets.all(isWide ? 24 : 12),
        color: const Color(0xFFF8F9FA),
        child: Column(
          children: [
            // ✅ Top Menu Bar (Responsive for Desktop)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 0, 114, 76),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "History Stock Report",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Row(
                    children: [
                      DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedMonth ?? 'All',
                          dropdownColor: const Color.fromARGB(255, 0, 123, 255),
                          iconEnabledColor:
                              const Color.fromARGB(255, 255, 255, 255),
                          style: const TextStyle(color: Colors.white),
                          items: [
                            const DropdownMenuItem(
                              value: 'All',
                              child: Text("All Months"),
                            ),
                            ...months
                                .map((m) => DropdownMenuItem(
                                      value: m,
                                      child: Text(m),
                                    ))
                                .toList(),
                          ],
                          onChanged: (val) {
                            setState(() {
                              selectedMonth = (val == 'All') ? null : val;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.download, color: Colors.white),
                        label: const Text('Export',
                            style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 0, 123, 255),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              title: const Text(
                                'Export Options',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.picture_as_pdf,
                                        color: Colors.white),
                                    label: const Text('Export PDF',
                                        style: TextStyle(color: Colors.white)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.redAccent,
                                      minimumSize:
                                          const Size(double.infinity, 45),
                                    ),
                                    onPressed: () {
                                      Navigator.pop(context);
                                      exportToPDF();
                                    },
                                  ),
                                  const SizedBox(height: 10),
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.grid_on,
                                        color: Colors.white),
                                    label: const Text('Export Excel',
                                        style: TextStyle(color: Colors.white)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      minimumSize:
                                          const Size(double.infinity, 45),
                                    ),
                                    onPressed: () {
                                      Navigator.pop(context);
                                      exportToExcel();
                                    },
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ✅ Data Table
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('inventory_history')
                    .orderBy('date', descending: true)
                    .snapshots(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child:
                          CircularProgressIndicator(color: Color(0xFF007BFF)),
                    );
                  }

                  final docs = snap.data?.docs
                          .where((d) => isSameMonth(d['date']))
                          .toList() ??
                      [];

                  if (docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'No data available',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    );
                  }

                  final rows = docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return DataRow(cells: [
                      DataCell(Text(data['course'] ?? '')),
                      DataCell(Text(data['gender'] ?? '')),
                      DataCell(Text(data['size'] ?? '')),
                      DataCell(Text(data['stockIn']?.toString() ?? '0')),
                      DataCell(Text(data['stockOut']?.toString() ?? '0')),
                      DataCell(Text(data['remaining']?.toString() ?? '0')),
                      DataCell(Text(formatDate(data['date']))),
                    ]);
                  }).toList();

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth:
                            isWide ? 950 : MediaQuery.of(context).size.width,
                      ),
                      child: DataTable(
                        headingRowColor: MaterialStateProperty.all(
                          const Color(0xFF00A86B).withOpacity(0.1),
                        ),
                        columns: const [
                          DataColumn(label: Text('Course')),
                          DataColumn(label: Text('Sex')),
                          DataColumn(label: Text('Size')),
                          DataColumn(label: Text('Stock In')),
                          DataColumn(label: Text('Stock Out')),
                          DataColumn(label: Text('Remaining')),
                          DataColumn(label: Text('Date')),
                        ],
                        rows: rows,
                      ),
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
