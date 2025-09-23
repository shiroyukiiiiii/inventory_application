import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class SalesReportPage extends StatefulWidget {
  const SalesReportPage({super.key});

  @override
  State<SalesReportPage> createState() => _SalesReportPageState();
}

class _SalesReportPageState extends State<SalesReportPage> {
  bool _loading = true;
  List<Map<String, dynamic>> _salesData = [];

  @override
  void initState() {
    super.initState();
    _loadExampleData(); // demo data
  }

  Future<void> _loadExampleData() async {
    await Future.delayed(const Duration(seconds: 1));
    final data = [
      {"id": "1", "amount": 450, "date": DateTime(2025, 1, 1)},
      {"id": "2", "amount": 700, "date": DateTime(2025, 1, 5)},
      {"id": "3", "amount": 300, "date": DateTime(2025, 2, 10)},
      {"id": "4", "amount": 900, "date": DateTime(2025, 3, 15)},
      {"id": "5", "amount": 650, "date": DateTime(2025, 4, 20)},
    ];

    setState(() {
      _salesData = data;
      _loading = false;
    });
  }

  int _getTotalSales() {
    return _salesData.fold<int>(
      0,
      (total, item) => total + (item["amount"] as int),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gradientColors = [Colors.blue.shade600, Colors.green.shade400];

    return _loading
        ? const Center(child: CircularProgressIndicator())
        : _salesData.isEmpty
            ? const Center(
                child: Text(
                  "No sales data available",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "📊 Monthly Sales Overview",
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Chart Section
                    Expanded(
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
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
                                    getTitlesWidget: (value, meta) {
                                      return Text(
                                        "₱${value.toInt()}",
                                        style: GoogleFonts.poppins(
                                          fontSize: 10,
                                          color: Colors.grey.shade700,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      if (value.toInt() >= _salesData.length) {
                                        return const SizedBox();
                                      }
                                      final date = _salesData[value.toInt()]
                                          ["date"] as DateTime;
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
                              barGroups:
                                  _salesData.asMap().entries.map((entry) {
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
                                      backDrawRodData:
                                          BackgroundBarChartRodData(
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

                    const SizedBox(height: 20),

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
                  ],
                ),
              );
  }
}
