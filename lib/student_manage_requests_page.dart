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

  /// Builds a request card with optional edit/cancel buttons
  Widget _buildRequestCard(BuildContext context, String docId,
      Map<String, dynamic> data,
      {bool showActions = true}) {
    final status = data['status'] ?? 'Pending';

    // Status colors
    Color statusColor;
    switch (status) {
      case 'Approved':
        statusColor = Colors.green;
        break;
      case 'Cancelled':
        statusColor = Colors.red;
        break;
      case 'Pending':
        statusColor = Colors.orange;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text('${data['course']} - ${data['size']}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Username: ${data['userName'] ?? ''}'),
            Text('Gender: ${data['gender'] ?? ''}'),
            Row(
              children: [
                const Text('Status: '),
                Text(
                  status,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
            Text(
              'Requested: ${_formatTimestamp(data['timestamp'])}',
            ),
          ],
        ),
        trailing: showActions
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _editRequest(context, docId, data),
                  ),
                  IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.red),
                    onPressed: () => _cancelRequest(context, docId),
                  ),
                ],
              )
            : null,
      ),
    );
  }

  /// Cancel request by updating the status
  void _cancelRequest(BuildContext context, String docId) async {
    await FirebaseFirestore.instance
        .collection('uniform_requests')
        .doc(docId)
        .update({'status': 'Cancelled'});

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Request cancelled')),
    );
  }

  /// Edit request (example: update size)
  void _editRequest(
      BuildContext context, String docId, Map<String, dynamic> data) {
    final sizeController = TextEditingController(text: data['size']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Request'),
        content: TextField(
          controller: sizeController,
          decoration: const InputDecoration(labelText: 'Size'),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text('Save'),
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('uniform_requests')
                  .doc(docId)
                  .update({'size': sizeController.text});

              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Request updated')),
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    final date = (timestamp is DateTime)
        ? timestamp
        : (timestamp is Timestamp)
            ? timestamp.toDate()
            : null;
    if (date == null) return 'N/A';
    return DateFormat('MMM d, yyyy • h:mm a').format(date);
  }
}
