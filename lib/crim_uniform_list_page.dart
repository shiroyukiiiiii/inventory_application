import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CrimUniformListPage extends StatelessWidget {
  const CrimUniformListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Crim Uniforms',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Color(0xFF012060),
              ),
            ),
            SizedBox(
              height: kToolbarHeight - 10,
              child: Image.asset(
                'assets/images/eclaroacademy.png',
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('uniforms')
            .where('course', isEqualTo: 'Crim')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No Crim uniforms found.'));
          }
          final uniforms = snapshot.data!.docs;
          return ListView.builder(
            itemCount: uniforms.length,
            itemBuilder: (context, index) {
              final data = uniforms[index].data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: data['imageUrl'] != null && data['imageUrl'] != ''
                      ? Image.network(data['imageUrl'], width: 50, height: 50, fit: BoxFit.cover)
                      : const Icon(Icons.image_not_supported, size: 50),
                  title: Text('${data['gender']} - ${data['size']}'),
                  subtitle: Text('Quantity: ${data['quantity'] ?? 0}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
