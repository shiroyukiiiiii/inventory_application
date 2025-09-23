import 'package:flutter/material.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  // Boys uniforms
  List<Map<String, dynamic>> boysUniforms = [
    {
      'name': 'BS Computer Science / BS Arts and Communication',
      'sizes': {'Small': 5, 'Medium': 10, 'Large': 8, 'XL': 6, '2XL': 4},
      'price': 1000
    },
    {
      'name': 'BS Criminology',
      'sizes': {'Small': 3, 'Medium': 5, 'Large': 4, 'XL': 2, '2XL': 1},
      'price': 1000
    },
  ];

  // Girls uniforms
  List<Map<String, dynamic>> girlsUniforms = [
    {
      'name': 'BS Computer Science / BS Arts and Communication',
      'sizes': {'Small': 5, 'XL': 6, '2XL': 4},
      'price': 1000
    },
    {
      'name': 'BS Criminology',
      'sizes': {'Small': 3, 'XL': 2, '2XL': 1},
      'price': 1000
    },
  ];

  int getTotalStock(List<Map<String, dynamic>> uniforms) {
    int total = 0;
    for (var item in uniforms) {
      total += (item['sizes'] as Map<String, dynamic>)
          .values
          .fold<num>(0, (sum, val) => sum + (val as num))
          .toInt();
    }
    return total;
  }

  int getTotalValue(List<Map<String, dynamic>> uniforms) {
    int total = 0;
    for (var item in uniforms) {
      int stock = (item['sizes'] as Map<String, dynamic>)
          .values
          .fold<num>(0, (sum, val) => sum + (val as num))
          .toInt();
      total += stock * (item['price'] as int);
    }
    return total;
  }

  int getOverallStock() {
    return getTotalStock(boysUniforms) + getTotalStock(girlsUniforms);
  }

  int getOverallValue() {
    return getTotalValue(boysUniforms) + getTotalValue(girlsUniforms);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[50],
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: _buildOverallCard()), // Centered horizontally
            const SizedBox(height: 12),
            _buildSummaryCard(
              title: 'Boys Uniforms',
              color: Colors.blue[100]!,
              uniforms: boysUniforms,
            ),
            _buildSummaryCard(
              title: 'Girls Uniforms',
              color: Colors.green[100]!,
              uniforms: girlsUniforms,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade400, Colors.blue.shade400],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Overall Inventory Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Total Stock: ${getOverallStock()} | Total Value: ₱${getOverallValue()}',
            style: const TextStyle(fontSize: 16, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required Color color,
    required List<Map<String, dynamic>> uniforms,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        color: color,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
              ),
              const SizedBox(height: 8),
              ...uniforms.map(
                (item) => Card(
                  color: Colors.white,
                  child: ListTile(
                    title: Text(item['name']),
                    subtitle: Text(
                        'Price: ₱${item['price']}\nSizes & Quantity: ${item['sizes']}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit, color: Colors.black87),
                      onPressed: () {
                        showEditDialog(item, uniforms: uniforms);
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Total Stock: ${getTotalStock(uniforms)} | Total Value: ₱${getTotalValue(uniforms)}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void showEditDialog(Map<String, dynamic> item,
      {required List<Map<String, dynamic>> uniforms}) {
    final priceController =
        TextEditingController(text: item['price'].toString());
    final Map<String, TextEditingController> sizeControllers = {};
    for (var size in item['sizes'].keys) {
      sizeControllers[size] =
          TextEditingController(text: item['sizes'][size].toString());
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Item'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Price'),
                ),
                const SizedBox(height: 10),
                ...item['sizes'].keys.map((size) {
                  return TextField(
                    controller: sizeControllers[size],
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: 'Quantity $size'),
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            ElevatedButton(
                onPressed: () {
                  setState(() {
                    item['price'] =
                        int.tryParse(priceController.text) ?? item['price'];
                    for (var size in item['sizes'].keys) {
                      item['sizes'][size] =
                          int.tryParse(sizeControllers[size]!.text) ??
                              item['sizes'][size];
                    }
                  });
                  Navigator.pop(context);
                },
                child: const Text('Save')),
          ],
        );
      },
    );
  }
}
