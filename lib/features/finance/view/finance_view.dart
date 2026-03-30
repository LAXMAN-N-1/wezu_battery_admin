import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/widgets/admin_ui_components.dart';
import '../data/models/transaction.dart';
import '../data/repositories/finance_repository.dart';

class FinanceView extends StatefulWidget {
  const FinanceView({super.key});

  @override
  State<FinanceView> createState() => _FinanceViewState();
}

class _FinanceViewState extends State<FinanceView> {
  final FinanceRepository _repository = FinanceRepository();
  bool _isLoading = true;
  double _totalRevenue = 0;
  double _monthlyGrowth = 0;
  List<Map<String, dynamic>> _chartData = [];
  List<Transaction> _transactions = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _repository.getFinanceDashboardData();
      setState(() {
        _totalRevenue = data['totalRevenue'];
        _monthlyGrowth = data['monthlyGrowth'];
        _chartData = List<Map<String, dynamic>>.from(data['revenueChart']);
        _transactions = List<Transaction>.from(data['recentTransactions']);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Stats
          PageHeader(
            title: 'Financial Overview',
            subtitle: 'Monitor revenue, growth, and recent transactions.',
            actionButton: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Total Revenue: ₹${NumberFormat.compact().format(_totalRevenue)}',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    '+$_monthlyGrowth%',
                    style: const TextStyle(color: Colors.green, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1),
          const SizedBox(height: 32),

          // Revenue Chart
          AdvancedCard(
            height: 300,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Monthly Revenue',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 10000,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: Colors.white.withValues(alpha: 0.1),
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() >= 0 && value.toInt() < _chartData.length) {
                                return SideTitleWidget(
                                  meta: meta,
                                  child: Text(
                                    _chartData[value.toInt()]['month'],
                                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                                  ),
                                );
                              }
                              return const SizedBox();
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                '₹${(value / 1000).toInt()}k',
                                style: const TextStyle(color: Colors.white54, fontSize: 10),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      minX: 0,
                      maxX: _chartData.length.toDouble() - 1,
                      minY: 0,
                      maxY: 80000, // Slightly above max mock data
                      lineBarsData: [
                        LineChartBarData(
                          spots: _chartData.asMap().entries.map((entry) {
                            return FlSpot(entry.key.toDouble(), entry.value['value']);
                          }).toList(),
                          isCurved: true,
                          color: Colors.blue,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: Colors.blue.withValues(alpha: 0.1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 500.ms, delay: 200.ms).slideX(begin: -0.05),
          const SizedBox(height: 32),

          // Transactions List
          Text(
            'Recent Transactions',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ).animate().fadeIn(delay: 300.ms),
          const SizedBox(height: 16),
          _buildTransactionList().animate().fadeIn(duration: 500.ms, delay: 400.ms).slideY(begin: 0.05),
        ],
      ),
    );
  }

  Widget _buildTransactionList() {
    return AdvancedCard(
      padding: EdgeInsets.zero,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _transactions.length,
        separatorBuilder: (context, index) => Divider(color: Colors.white.withValues(alpha: 0.05), height: 1),
        itemBuilder: (context, index) {
          final txn = _transactions[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              child: Icon(
                txn.status == 'success' ? Icons.arrow_outward : Icons.warning_amber_rounded,
                color: txn.status == 'success' ? Colors.green : Colors.red,
                size: 20,
              ),
            ),
            title: Text(
              txn.type.toUpperCase().replaceAll('_', ' '),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '${txn.userName} • ${DateFormat('MMM d, h:mm a').format(txn.timestamp)}',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
            trailing: Text(
              '₹${txn.amount.toStringAsFixed(2)}',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          );
        },
      ),
    );
  }
}
