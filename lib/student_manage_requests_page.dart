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
        appBar: AppBar(
          title: Row(
            children: [
              const Text('My Uniform Requests'),
              const SizedBox(width: 10),
              CircleAvatar(
                backgroundImage: NetworkImage(user.photoURL ?? ''),
                radius: 15,
              ),
              const SizedBox(width: 5),
              Text(
                user.displayName ?? '',
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Orders'),
              Tab(text: 'Cancelled Orders'),
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
              return const Center(child: Text('No requests found.'));
            }

            final allRequests = snapshot.data!.docs;

            // Split requests
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
                // Orders Tab
                orders.isEmpty
                    ? const Center(child: Text('No active orders.'))
                    : ListView.builder(
                        itemCount: orders.length,
                        itemBuilder: (context, index) {
                          final doc = orders[index];
                          final data = doc.data() as Map<String, dynamic>;
                          return _buildRequestCard(context, doc.id, data);
                        },
                      ),

                // Cancelled Orders Tab
                cancelledOrders.isEmpty
                    ? const Center(child: Text('No cancelled orders.'))
                    : ListView.builder(
                        itemCount: cancelledOrders.length,
                        itemBuilder: (context, index) {
                          final doc = cancelledOrders[index];
                          final data = doc.data() as Map<String, dynamic>;
                          return _buildRequestCard(
                            context,
                            doc.id,
                            data,
                            showActions: false, // hide buttons
                          );
                        },
                      ),
              ],
            );
          },
        ),
      ),
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
      requestTime = DateFormat('MMM d, yyyy hh:mm a').format(timestamp.toDate());
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Request #${requestId.substring(0, 8)}...',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Status: ${data['status'] ?? 'Pending'}',
                        style: TextStyle(
                          color: _getStatusColor(data['status'] ?? 'Pending'),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (showActions) ...[
                  IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.red),
                    tooltip: 'Cancel Request',
                    onPressed: () => _cancelRequest(context, requestId),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Gender', data['gender'] ?? ''),
            _buildInfoRow('Course', data['course'] ?? ''),
            _buildInfoRow('Size', data['size'] ?? ''),
            _buildInfoRow('Student ID', data['studentId'] ?? ''),
            _buildInfoRow('Requested', requestTime),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
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
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.red)),
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
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error cancelling request: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}