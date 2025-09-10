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
        ),
      ),
    );
  }
}
