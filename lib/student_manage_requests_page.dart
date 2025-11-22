import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class StudentManageRequestsPage extends StatelessWidget {
  final User user;
  const StudentManageRequestsPage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isPhone = screenWidth < 500;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        
        appBar: AppBar(
  elevation: 0,
  backgroundColor: Colors.white,
  automaticallyImplyLeading: false,

  title: Stack(
    alignment: Alignment.center,
    children: [
      // Centered Logo
      SizedBox(
        height: kToolbarHeight - 10,
        child: Image.asset(
          'assets/images/eclaroacademy.png',
          fit: BoxFit.contain,
        ),
      ),

      // Left Text
      
      Align(
  alignment: Alignment.centerLeft,
  child: Row(
    mainAxisSize: MainAxisSize.min, // prevents row from stretching
    children: [
      IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF012060)),
        onPressed: () => Navigator.pop(context),
      ),
      const Text(
        'My Requests',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 20,
          color: Color(0xFF012060),
        ),
      ),
    ],
  ),
)

    ],
  ),

  bottom: TabBar(
    indicatorColor: Colors.white,
    labelColor: Colors.white,
    unselectedLabelColor: Colors.white70,
    labelStyle: TextStyle(
      fontSize: isPhone ? 12 : 14,
      fontWeight: FontWeight.bold,
    ),
    tabs: const [
      Tab(icon: Icon(Icons.list_alt_rounded), text: 'Orders'),
      Tab(icon: Icon(Icons.check_circle_outline), text: 'Completed'),
      Tab(icon: Icon(Icons.cancel_outlined), text: 'Cancelled'),
    ],
  ),
),

        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('uniform_requests')
              .where('userId', isEqualTo: user.uid)
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text(
                  'No requests found.',
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
              );
            }

            final allRequests = snapshot.data!.docs;

            final orders = allRequests.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final status = (data['status'] ?? 'Pending').toString();
              return status != 'Cancelled' && status != 'Completed';
            }).toList();

            final completedOrders = allRequests.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return (data['status'] ?? '') == 'Completed';
            }).toList();

            final cancelledOrders = allRequests.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return (data['status'] ?? '') == 'Cancelled';
            }).toList();

            return TabBarView(
              children: [
                _buildListView(context, orders,
                    emptyMessage: 'No active orders.'),
                _buildListView(context, completedOrders,
                    emptyMessage: 'No completed orders.', showActions: false),
                _buildListView(context, cancelledOrders,
                    emptyMessage: 'No cancelled orders.', showActions: false),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildListView(BuildContext context, List<DocumentSnapshot> requests,
      {String emptyMessage = '', bool showActions = true}) {
    if (requests.isEmpty) {
      return Center(
        child: Text(emptyMessage,
            style: const TextStyle(color: Colors.black54, fontSize: 14)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final doc = requests[index];
        final data = doc.data() as Map<String, dynamic>;
        return _buildRequestCard(context, doc.id, data,
            showActions: showActions);
      },
    );
  }

  Widget _buildRequestCard(
    BuildContext context,
    String requestId,
    Map<String, dynamic> data, {
    bool showActions = true,
  }) {
    final timestamp = data['timestamp'];
    String requestTime = 'N/A';
    if (timestamp is Timestamp) {
      requestTime =
          DateFormat('MMM d, yyyy hh:mm a').format(timestamp.toDate());
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Request #${requestId.substring(0, 6)}...',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF012060),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (showActions)
                  IconButton(
                    icon: const Icon(Icons.cancel_outlined,
                        color: Colors.redAccent, size: 20),
                    tooltip: 'Cancel Request',
                    onPressed: () => _cancelRequest(context, requestId),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _getStatusColor(data['status'] ?? 'Pending')
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                data['status'] ?? 'Pending',
                style: TextStyle(
                  color: _getStatusColor(data['status'] ?? 'Pending'),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            const Divider(height: 18, color: Colors.grey),
            _buildInfoRow(Icons.male_rounded, 'Gender', data['gender'] ?? ''),
            _buildInfoRow(Icons.school_rounded, 'Course', data['course'] ?? ''),
            _buildInfoRow(Icons.straighten_rounded, 'Size', data['size'] ?? ''),
            _buildInfoRow(
                Icons.badge_rounded, 'Student ID', data['studentId'] ?? ''),
            _buildInfoRow(Icons.access_time, 'Requested', requestTime),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Color(0xFF012060)),
          const SizedBox(width: 6),
          Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Color(0xFF98C93E);
      case 'completed':
        return const Color(0xFF012060);
      case 'cancelled':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  Future<void> _cancelRequest(BuildContext context, String requestId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Request'),
        content: const Text('Are you sure you want to cancel this request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Cancel',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('uniform_requests')
            .doc(requestId)
            .update({'status': 'Cancelled'});

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Request cancelled successfully!'),
              backgroundColor: Color(0xFF00796B),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error cancelling request: $e'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }
}
