import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// Make sure you have this file created
import 'admin_qr_confirmation.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// ✅ Added missing FAB builder
  Widget _buildFab() {
    return FloatingActionButton(
      onPressed: () {
        // Example: Navigate to QR scanner confirmation page
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AdminQrConfirmationPage()),
        );
      },
      child: const Icon(Icons.add),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
}

/// ---------------------
/// INVENTORY TAB
/// ---------------------
class _InventoryTab extends StatelessWidget {
  const _InventoryTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('uniform_inventory').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final uniforms = snapshot.data!.docs;

        return ListView.builder(
          itemCount: uniforms.length,
          itemBuilder: (context, index) {
            final data = uniforms[index].data() as Map<String, dynamic>;
            return Card(
              child: ListTile(
                title: Text(data['type'] ?? 'Unknown'),
                subtitle: Text('Size: ${data['size'] ?? 'N/A'}'),
                trailing: Text('Stock: ${data['stock']?.toString() ?? '0'}'),
              ),
            );
          },
        );
      },
    );
  }
}

/// ---------------------
/// UNIFORM REQUESTS TAB
/// ---------------------
class UniformRequestsListPage extends StatelessWidget {
  const UniformRequestsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('uniform_requests')
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final requests = snapshot.data!.docs;
        if (requests.isEmpty) {
          return const Center(child: Text('No pending requests.'));
        }

        return ListView.builder(
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final data = requests[index].data() as Map<String, dynamic>;
            return Card(
              child: ListTile(
                title: Text(data['student_name'] ?? 'Unknown'),
                subtitle: Text(
                    '${data['course'] ?? ''} - ${data['gender'] ?? ''} (Size: ${data['size'] ?? ''})'),
                trailing: ElevatedButton(
                  onPressed: () async {
                    await FirebaseFirestore.instance
                        .collection('uniform_requests')
                        .doc(requests[index].id)
                        .update({'status': 'approved'});
                  },
                  child: const Text('Approve'),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// ---------------------
/// COMPLETED ORDERS TAB
/// ---------------------
class CompletedOrdersListPage extends StatelessWidget {
  const CompletedOrdersListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('uniform_requests')
          .where('status', isEqualTo: 'completed')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final completedOrders = snapshot.data!.docs;
        if (completedOrders.isEmpty) {
          return const Center(child: Text('No completed orders.'));
        }

        return ListView.builder(
          itemCount: completedOrders.length,
          itemBuilder: (context, index) {
            final data = completedOrders[index].data() as Map<String, dynamic>;
            return Card(
              child: ListTile(
                title: Text(data['student_name'] ?? 'Unknown'),
                subtitle: Text(
                    '${data['course'] ?? ''} - ${data['gender'] ?? ''} (Size: ${data['size'] ?? ''})'),
                trailing: const Icon(Icons.check, color: Colors.green),
              ),
            );
          },
        );
      },
    );
  }
}
