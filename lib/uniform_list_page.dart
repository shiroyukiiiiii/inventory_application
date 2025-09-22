import 'package:flutter/material.dart';

class UniformListPage extends StatefulWidget {
  const UniformListPage({super.key});

  @override
  State<UniformListPage> createState() => _UniformListPageState();
}

class _UniformListPageState extends State<UniformListPage> {
  String selectedUniform = 'Male'; // initialValue instead of deprecated `value`

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Uniform List')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
<<<<<<< HEAD
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Gender', style: TextStyle(fontSize: 16)),
                    ...['Male', 'Female'].map((gender) => RadioListTile<String>(
                          title: Text(gender),
                          value: gender,
                          groupValue: _gender,
                          onChanged: (value) {
                            setState(() {
                              _gender = value ?? '';
                            });
                          },
                        )),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Course', style: TextStyle(fontSize: 16)),
                    ...['BSCRIM', 'ABCOM', 'BSCS'].map((course) => RadioListTile<String>(
                          title: Text(course),
                          value: course,
                          groupValue: _course,
                          onChanged: (value) {
                            setState(() {
                              _course = value ?? '';
                            });
                          },
                        )),
                  ],
                ),
              ),
                DropdownButtonFormField<String>(
                  initialValue: _size.isNotEmpty ? _size : null,
                  decoration: const InputDecoration(labelText: 'Size'),
                  items: ['XS', 'S', 'M', 'L', 'XL', 'XXL']
                      .map((size) => DropdownMenuItem(
                            value: size,
                            child: Text(size),
                          ))
                      .toList(),
                  validator: (value) => value == null || value.isEmpty ? 'Select size' : null,
                  onChanged: (value) {
                    setState(() {
                      _size = value ?? '';
                    });
                  },
                  onSaved: (value) => _size = value ?? '',
                ),
              TextFormField(
                initialValue: _quantity.toString(),
                decoration: const InputDecoration(labelText: 'Quantity'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Enter quantity';
                  final n = int.tryParse(value);
                  if (n == null || n < 0) return 'Enter a valid quantity';
                  return null;
                },
                onSaved: (value) => _quantity = int.parse(value!),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveUniform,
                      child: Text(widget.uniform == null ? 'Add' : 'Update'),
                    ),
                  ),
                  if (widget.uniform != null) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        onPressed: _deleteUniform,
                        child: const Text('Delete'),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
=======
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              initialValue: selectedUniform,
              onChanged: (val) {
                setState(() {
                  selectedUniform = val!;
                });
              },
              items: const [
                DropdownMenuItem(value: 'Male', child: Text('Male')),
                DropdownMenuItem(value: 'Female', child: Text('Female')),
              ],
              decoration: const InputDecoration(
                labelText: 'Select Uniform',
              ),
            ),
          ],
>>>>>>> mainfeatures
        ),
      ),
    );
  }
}
