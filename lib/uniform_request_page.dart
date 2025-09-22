import 'package:flutter/material.dart';

class UniformRequestPage extends StatefulWidget {
  const UniformRequestPage({super.key});

  @override
  State<UniformRequestPage> createState() => _UniformRequestPageState();
}

class _UniformRequestPageState extends State<UniformRequestPage> {
<<<<<<< HEAD
  final _formKey = GlobalKey<FormState>();
  late String _gender;
  late String _course;
  String _size = '';
  String _studentId = '';
  String _name = '';
  String _email = '';
  bool _isSubmitting = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _gender = widget.initialGender ?? '';
    _course = widget.initialCourse ?? '';
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() {
      _isSubmitting = true;
      _message = null;
    });
    try {
      await FirebaseFirestore.instance.collection('uniform_requests').add({
        'userId': widget.user.uid,
        'name': _name,
        'email': _email,
        'gender': _gender,
        'course': _course,
        'size': _size,
        'studentId': _studentId,
        'timestamp': FieldValue.serverTimestamp(),
      });
      setState(() {
        _message = 'Request submitted!';
      });
      _formKey.currentState?.reset();
    } catch (e) {
      setState(() {
        _message = 'Error: $e';
      });
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }
=======
  String selectedType = 'Male';
  String selectedSize = 'M';
>>>>>>> mainfeatures

  @override
  Widget build(BuildContext context) {
    return Scaffold(
<<<<<<< HEAD
      appBar: AppBar(title: const Text('Request Uniform')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Full Name (letters + spaces only)
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Full Name'),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Enter your name';
                        if (!RegExp(r"^[a-zA-Z\s]+$").hasMatch(value)) {
                          return 'Name can only contain letters and spaces';
                        }
                        return null;
                      },
                      onSaved: (value) => _name = value!.trim(),
                    ),
                    // Email (strict format)
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Enter your email';
                        final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$');
                        if (!emailRegex.hasMatch(value)) return 'Enter a valid email address';
                        return null;
                      },
                      onSaved: (value) => _email = value!.trim(),
                    ),
                    // Student Number (digits only, 8 length example)
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Student Number'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Enter Student Number';
                        if (!RegExp(r'^\d{8}$').hasMatch(value)) {
                          return 'Student Number must be 8 digits';
                        }
                        return null;
                      },
                      onSaved: (value) => _studentId = value!.trim(),
                    ),
                    // Gender dropdown
                    DropdownButtonFormField<String>(
                      initialValue: _gender.isNotEmpty ? _gender : null,
                      decoration: const InputDecoration(labelText: 'Gender'),
                      items: const [
                        DropdownMenuItem(value: 'Male', child: Text('Male')),
                        DropdownMenuItem(value: 'Female', child: Text('Female')),
                      ],
                      validator: (value) => value == null || value.isEmpty ? 'Select gender' : null,
                      onChanged: (value) => setState(() => _gender = value ?? ''),
                      onSaved: (value) => _gender = value ?? '',
                    ),
                    // Course dropdown
                    DropdownButtonFormField<String>(
                      initialValue: _course.isNotEmpty ? _course : null,
                      decoration: const InputDecoration(labelText: 'Course'),
                      items: const [
                        DropdownMenuItem(value: 'BSCS', child: Text('BSCS')),
                        DropdownMenuItem(value: 'ABCOM', child: Text('ABCOM')),
                        DropdownMenuItem(value: 'BSCRIM', child: Text('BSCRIM')),
                      ],
                      validator: (value) => value == null || value.isEmpty ? 'Select course' : null,
                      onChanged: (value) => setState(() => _course = value ?? ''),
                      onSaved: (value) => _course = value ?? '',
                    ),
                    // Uniform size radio buttons
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('uniforms')
                          .where('gender', isEqualTo: _gender)
                          .where('course', isEqualTo: _course)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Text('No inventory data found for selected gender/course.');
                        }
                        final uniformData = snapshot.data!.docs;
                        final Map<String, int> sizeInventory = {};
                        for (var doc in uniformData) {
                          final data = doc.data() as Map<String, dynamic>;
                          sizeInventory[data['size']] = data['quantity'] ?? 0;
                        }
                        final sizes = ['XS', 'S', 'M', 'L', 'XL', 'XXL'];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Select Size:', style: TextStyle(fontWeight: FontWeight.bold)),
                            ...sizes.map((size) {
                              final qty = sizeInventory[size] ?? 0;
                              return RadioListTile<String>(
                                title: Text('$size  •  Available: $qty'),
                                value: size,
                                groupValue: _size,
                                onChanged: qty > 0
                                    ? (value) => setState(() => _size = value ?? '')
                                    : null,
                                activeColor: Colors.blue,
                                secondary: qty == 0
                                    ? const Icon(Icons.block, color: Colors.red)
                                    : null,
                              );
                            }),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    _isSubmitting
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                            onPressed: _submitRequest,
                            child: const Text('Submit Request'),
                          ),
                    if (_message != null) ...[
                      const SizedBox(height: 20),
                      Text(
                        _message!,
                        style: TextStyle(
                          color: _message == 'Request submitted!'
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
=======
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
>>>>>>> mainfeatures
        ),
      ),
    );
  }
}
