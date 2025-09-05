import 'package:flutter/material.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.blue[300],
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(12),
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        children: const [
          DashboardCard(
            title: 'Manage Requests',
            icon: Icons.assignment,
            routeName: '/uniform-requests',
          ),
          DashboardCard(
            title: 'Uniform Inventory',
            icon: Icons.inventory,
            routeName: '/uniform-inventory', //
          ),
          DashboardCard(
            title: 'Student Accounts',
            icon: Icons.people,
            routeName: '/student-accounts',
          ),
          DashboardCard(
            title: 'Reports',
            icon: Icons.bar_chart,
            routeName: '/reports',
          ),
        ],
      ),
    );
  }
}

class DashboardCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String routeName;

  const DashboardCard({
    required this.title,
    required this.icon,
    required this.routeName,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          print('Navigating to $routeName');
          Navigator.pushNamed(context, routeName);
        },
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: Colors.blue),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
