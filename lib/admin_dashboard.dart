import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:inventory_application/inventory_page.dart';

import 'salesreport_page.dart';

class AdminDashboardApp extends StatefulWidget {
  const AdminDashboardApp({super.key});

  @override
  State<AdminDashboardApp> createState() => _AdminDashboardAppState();
}

class _AdminDashboardAppState extends State<AdminDashboardApp> {
  int _selectedIndex = 0;

  bool _loading = true;
  List<Map<String, dynamic>> _salesData = [];
  List<Map<String, dynamic>> _stockData = [];

  @override
  void initState() {
    super.initState();
    _loadExampleData();
  }

  Future<void> _loadExampleData() async {
    await Future.delayed(const Duration(seconds: 1));

    _salesData = [
      {"id": "1", "amount": 450, "date": DateTime(2025, 1, 1)},
      {"id": "2", "amount": 700, "date": DateTime(2025, 1, 5)},
      {"id": "3", "amount": 300, "date": DateTime(2025, 2, 10)},
      {"id": "4", "amount": 900, "date": DateTime(2025, 3, 15)},
      {"id": "5", "amount": 650, "date": DateTime(2025, 4, 20)},
    ];

    _stockData = [
      {"item": "Uniform A", "quantity": 120},
      {"item": "Uniform B", "quantity": 80},
      {"item": "Uniform C", "quantity": 45},
    ];

    setState(() {
      _loading = false;
    });
  }

  int _getTotalSales() {
    return _salesData.fold<int>(
      0,
      (total, item) => total + (item["amount"] as int),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // -------------------- Pages --------------------
  Widget _buildDashboard() {
    final gradientColors = [Colors.blue.shade600, Colors.green.shade400];

    return _loading
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Sales Chart
                Expanded(
                  flex: 3,
                  child: Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 5,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: BarChart(
                        BarChartData(
                          gridData: FlGridData(
                            show: true,
                            getDrawingHorizontalLine: (value) => FlLine(
                              color: Colors.grey.shade300,
                              dashArray: [5, 5],
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                getTitlesWidget: (value, meta) => Text(
                                  "₱${value.toInt()}",
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  if (value.toInt() >= _salesData.length) {
                                    return const SizedBox();
                                  }
                                  final date = _salesData[value.toInt()]["date"]
                                      as DateTime;
                                  return Text(
                                    DateFormat("MMM d").format(date),
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.blue.shade600,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          barGroups: _salesData.asMap().entries.map((entry) {
                            int index = entry.key;
                            var sale = entry.value;
                            return BarChartGroupData(
                              x: index,
                              barRods: [
                                BarChartRodData(
                                  toY: (sale["amount"] as num).toDouble(),
                                  gradient: LinearGradient(
                                    colors: gradientColors,
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                  ),
                                  width: 18,
                                  borderRadius: BorderRadius.circular(8),
                                  backDrawRodData: BackgroundBarChartRodData(
                                    show: true,
                                    toY: 1000,
                                    color: Colors.grey.shade200,
                                  ),
                                )
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Total Sales Summary
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradientColors,
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    "Total Sales: ₱${_getTotalSales()}",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Remaining Stocks
                Expanded(
                  flex: 2,
                  child: ListView.builder(
                    itemCount: _stockData.length,
                    itemBuilder: (context, index) {
                      final stock = _stockData[index];
                      return Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          leading: Icon(Icons.inventory_2,
                              color: Colors.orange.shade600),
                          title: Text(
                            stock["item"],
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600),
                          ),
                          trailing: Text(
                            stock["quantity"].toString(),
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
  }

  Widget _buildSalesPage() {
    return const SalesReportPage();
  }

  Widget _buildInventoryPage() {
    return const InventoryPage();
  }

  Widget _buildManageRequestsPage() {
    return Center(
      child: Text(
        "Manage Requests Page",
        style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildMorePage() {
    final moreOptions = [
      {"title": "Settings", "icon": Icons.settings},
      {"title": "Admins", "icon": Icons.admin_panel_settings},
      {"title": "Students", "icon": Icons.people},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: moreOptions.length,
      itemBuilder: (context, index) {
        final option = moreOptions[index];
        return Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            leading:
                Icon(option["icon"] as IconData, color: Colors.blue.shade700),
            title: Text(
              option["title"] as String,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              debugPrint("${option["title"]} tapped");
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> pages = [
      _buildDashboard(),
      _buildSalesPage(),
      _buildInventoryPage(),
      _buildManageRequestsPage(),
      _buildMorePage(),
    ];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => debugPrint("Back pressed"),
        ),
        title: Text(
          [
            "Dashboard",
            "Sales",
            "Inventory",
            "Requests",
            "More"
          ][_selectedIndex],
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () => debugPrint("Notifications clicked"),
          )
        ],
        backgroundColor: Colors.green.shade700,
        elevation: 6,
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue.shade700,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Sales'),
          BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2), label: 'Inventory'),
          BottomNavigationBarItem(
              icon: Icon(Icons.assignment), label: 'Requests'),
          BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: 'More'),
        ],
      ),
    );
  }
}
