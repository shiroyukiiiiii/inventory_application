import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class StudentManageRequestsPage extends StatelessWidget {
  final User user;
  const StudentManageRequestsPage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Orders + Cancelled Orders
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(255, 0, 126, 61), // Solid green
          elevation: 3,
          title: Row(
            children: [
              const Icon(Icons.shopping_bag_rounded, color: Colors.white),
              const SizedBox(width: 8),
              const Text(
                'My Uniform Requests',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
              const Spacer(),
              CircleAvatar(
                backgroundImage: NetworkImage(user.photoURL ?? ''),
                radius: 16,
                backgroundColor: Colors.white24,
              ),
              const SizedBox(width: 6),
              Text(
                user.displayName ?? '',
                style: const TextStyle(fontSize: 15, color: Colors.white),
              ),
            ],
          ),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(icon: Icon(Icons.list_alt_rounded), text: 'Orders'),
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
              return (data['status'] ?? 'Pending') != 'Cancelled';
            }).toList();

            final cancelledOrders = allRequests.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return (data['status'] ?? '') == 'Cancelled';
            }).toList();

            return TabBarView(
              children: [
                _buildListView(context, orders,
                    emptyMessage: 'No active orders.'),
                _buildListView(
                  context,
                  cancelledOrders,
                  emptyMessage: 'No cancelled orders.',
                  showActions: false,
                ),
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
        child:
            Text(emptyMessage, style: const TextStyle(color: Colors.black54)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Request #${requestId.substring(0, 8)}...',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 0, 150, 60),
                    ),
                  ),
                ),
                if (showActions)
                  IconButton(
                    icon: const Icon(Icons.cancel_outlined,
                        color: Colors.redAccent),
                    tooltip: 'Cancel Request',
                    onPressed: () => _cancelRequest(context, requestId),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(data['status'] ?? 'Pending')
                    .withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                data['status'] ?? 'Pending',
                style: TextStyle(
                  color: _getStatusColor(data['status'] ?? 'Pending'),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Divider(height: 20, color: Colors.grey),
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
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Color(0xFF1976D2)),
          const SizedBox(width: 8),
          Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87),
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
        return Color.fromARGB(255, 2, 149, 56); // Green
      case 'completed':
        return Color(0xFF1976D2); // Blue
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
