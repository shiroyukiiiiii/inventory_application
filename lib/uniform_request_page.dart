import 'package:flutter/material.dart';

class UniformRequestPage extends StatefulWidget {
  const UniformRequestPage({super.key});

  @override
  State<UniformRequestPage> createState() => _UniformRequestPageState();
}

class _UniformRequestPageState extends State<UniformRequestPage> {
  String selectedType = 'Male';
  String selectedSize = 'M';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Uniform Request')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Uniform Type:'),
            Wrap(
              spacing: 10,
              children: ['Male', 'Female'].map((type) {
                return ChoiceChip(
                  label: Text(type),
                  selected: selectedType == type,
                  onSelected: (_) {
                    setState(() {
                      selectedType = type;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            const Text('Select Size:'),
            Wrap(
              spacing: 10,
              children: ['S', 'M', 'L'].map((size) {
                return ChoiceChip(
                  label: Text(size),
                  selected: selectedSize == size,
                  onSelected: (_) {
                    setState(() {
                      selectedSize = size;
                    });
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
