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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[50],
      appBar: AppBar(
        title: const Text('Inventory Management'),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              showAddDialog();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Boys section
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Boys Uniforms',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue)),
            ),
            ...boysUniforms.map((item) => Card(
                  color: Colors.blue[50],
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text(item['name']),
                    subtitle: Text(
                        'Price: ₱${item['price']}\nSizes & Quantity: ${item['sizes']}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () {
                        showEditDialog(item);
                      },
                    ),
                  ),
                )),

            // Girls section
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Girls Uniforms',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.pink)),
            ),
            ...girlsUniforms.map((item) => Card(
                  color: Colors.pink[50],
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text(item['name']),
                    subtitle: Text(
                        'Price: ₱${item['price']}\nSizes & Quantity: ${item['sizes']}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () {
                        showEditDialog(item, isGirls: true);
                      },
                    ),
                  ),
                )),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        color: Colors.green[100],
        child: Text(
          'Boys Total Stock: ${getTotalStock(boysUniforms)} | Boys Total Value: ₱${getTotalValue(boysUniforms)}\n'
          'Girls Total Stock: ${getTotalStock(girlsUniforms)} | Girls Total Value: ₱${getTotalValue(girlsUniforms)}',
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
      ),
    );
  }

  void showEditDialog(Map<String, dynamic> item, {bool isGirls = false}) {
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

  void showAddDialog() {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    Map<String, int> sizes = {};

    List<String> uniformSizes = ['Small', 'Medium', 'Large', 'XL', '2XL'];
    bool isGirls = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Add Uniform'),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: nameController,
                    decoration:
                        const InputDecoration(labelText: 'Uniform Name'),
                  ),
                  TextField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Price'),
                  ),
                  Row(
                    children: [
                      const Text('Gender:'),
                      const SizedBox(width: 10),
                      DropdownButton<bool>(
                        value: isGirls,
                        items: const [
                          DropdownMenuItem(value: false, child: Text('Boys')),
                          DropdownMenuItem(value: true, child: Text('Girls')),
                        ],
                        onChanged: (value) {
                          setStateDialog(() {
                            isGirls = value!;
                            uniformSizes = isGirls
                                ? ['Small', 'XL', '2XL']
                                : ['Small', 'Medium', 'Large', 'XL', '2XL'];
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...uniformSizes.map((size) {
                    sizes[size] = 0;
                    return TextField(
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: 'Quantity $size'),
                      onChanged: (val) {
                        sizes[size] = int.tryParse(val) ?? 0;
                      },
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
                    final newUniform = {
                      'name': nameController.text,
                      'price': int.tryParse(priceController.text) ?? 0,
                      'sizes': sizes,
                    };
                    setState(() {
                      if (isGirls) {
                        girlsUniforms.add(newUniform);
                      } else {
                        boysUniforms.add(newUniform);
                      }
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Add')),
            ],
          );
        });
      },
    );
  }
}
