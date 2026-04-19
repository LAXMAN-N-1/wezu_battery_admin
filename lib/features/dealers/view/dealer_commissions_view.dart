import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/admin_ui_components.dart';
import '../data/repositories/dealer_repository.dart';
import '../data/models/commission.dart';

class DealerCommissionsView extends StatefulWidget {
  const DealerCommissionsView({super.key});

  @override
  State<DealerCommissionsView> createState() => _DealerCommissionsViewState();
}

class _DealerCommissionsViewState extends State<DealerCommissionsView>
    with SingleTickerProviderStateMixin {
  final DealerRepository _repository = DealerRepository();
  List<CommissionConfig> _configs = [];
  List<CommissionLog> _logs = [];
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      _repository.getCommissionConfigs(),
      _repository.getCommissionLogs(),
      _repository.getCommissionStats(),
    ]);
    setState(() {
      _configs = results[0] as List<CommissionConfig>;
      _logs = results[1] as List<CommissionLog>;
      _stats = results[2] as Map<String, dynamic>;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'Commissions',
            subtitle:
                'Configure commission rates and track earnings across the dealer network.',
            actionButton: ElevatedButton.icon(
              onPressed: _showCreateConfigDialog,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('New Config'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1),
          const SizedBox(height: 24),

          // Stats
          Row(
            children: [
              _buildStatCard(
                'Total Paid',
                '₹${NumberFormat('#,##0.00').format(_stats['total_paid'] ?? 0)}',
                Icons.payments_outlined,
                const Color(0xFF22C55E),
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                'Pending',
                '₹${NumberFormat('#,##0.00').format(_stats['total_pending'] ?? 0)}',
                Icons.pending_outlined,
                const Color(0xFFF59E0B),
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                'Active Configs',
                '${_stats['active_configs'] ?? 0}',
                Icons.tune_outlined,
                const Color(0xFF3B82F6),
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                'Earnings Log',
                '${_logs.length} entries',
                Icons.history_outlined,
                const Color(0xFF8B5CF6),
              ),
            ],
          ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
          const SizedBox(height: 24),

          // Tabs
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(14),
            ),
            child: TabBar(
              controller: _tabController,
              onTap: (_) => setState(() {}),
              indicator: BoxDecoration(
                color: const Color(0xFF3B82F6),
                borderRadius: BorderRadius.circular(12),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white54,
              dividerColor: Colors.transparent,
              padding: const EdgeInsets.all(4),
              tabs: const [
                Tab(text: 'Commission Configs'),
                Tab(text: 'Earnings Log'),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 150.ms),
          const SizedBox(height: 24),

          // Content
          if (_isLoading)
            const SizedBox(
              height: 400,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_tabController.index == 0)
            _buildConfigsTab()
          else
            _buildLogsTab(),
        ],
      ),
    );
  }

  Widget _buildConfigsTab() {
    if (_configs.isEmpty) {
      return const SizedBox(
        height: 300,
        child: Center(
          child: Text(
            'No commission configs found.',
            style: TextStyle(color: Colors.white54),
          ),
        ),
      );
    }
    return AdvancedCard(
      padding: EdgeInsets.zero,
      child: AdvancedTable(
        columns: const [
          'ID',
          'Dealer',
          'Transaction Type',
          '%',
          'Flat Fee',
          'Status',
          'Effective From',
          'Actions',
        ],
        rows: _configs
            .map(
              (c) => [
                Text(
                  '#${c.id}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                Text(
                  c.dealerName ?? 'N/A',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    c.transactionType.toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFF3B82F6),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '${c.percentage}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '₹${c.flatFee.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.white70),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        (c.isActive
                                ? const Color(0xFF22C55E)
                                : const Color(0xFFEF4444))
                            .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    c.isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      color: c.isActive
                          ? const Color(0xFF22C55E)
                          : const Color(0xFFEF4444),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  c.effectiveFrom != null
                      ? DateFormat('MMM dd, yyyy').format(c.effectiveFrom!)
                      : '—',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                _buildConfigActions(c),
              ],
            )
            .toList(),
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 200.ms).slideY(begin: 0.05);
  }

  Widget _buildConfigActions(CommissionConfig c) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(
            Icons.edit_outlined,
            color: Colors.white54,
            size: 18,
          ),
          onPressed: () => _showEditConfigDialog(c),
        ),
        IconButton(
          icon: Icon(
            c.isActive ? Icons.pause_outlined : Icons.play_arrow_outlined,
            color: Colors.white54,
            size: 18,
          ),
          onPressed: () async {
            await _repository.updateCommissionConfig(c.id, {
              'is_active': !c.isActive,
            });
            _loadData();
          },
        ),
      ],
    );
  }

  Widget _buildLogsTab() {
    if (_logs.isEmpty) {
      return const SizedBox(
        height: 300,
        child: Center(
          child: Text(
            'No commission logs found.',
            style: TextStyle(color: Colors.white54),
          ),
        ),
      );
    }
    return AdvancedCard(
      padding: EdgeInsets.zero,
      child: AdvancedTable(
        columns: const ['ID', 'Dealer', 'Amount', 'Status', 'Date'],
        rows: _logs
            .map(
              (l) => [
                Text(
                  '#${l.id}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                Text(
                  l.dealerName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '₹${l.amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Color(0xFF22C55E),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        (l.status == 'paid'
                                ? const Color(0xFF22C55E)
                                : const Color(0xFFF59E0B))
                            .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    l.status.toUpperCase(),
                    style: TextStyle(
                      color: l.status == 'paid'
                          ? const Color(0xFF22C55E)
                          : const Color(0xFFF59E0B),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  l.createdAt != null
                      ? DateFormat('MMM dd, yyyy').format(l.createdAt!)
                      : '—',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            )
            .toList(),
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 200.ms).slideY(begin: 0.05);
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: AdvancedCard(
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateConfigDialog() {
    final txTypeCtrl = TextEditingController(text: 'rental');
    final pctCtrl = TextEditingController(text: '10');
    final feeCtrl = TextEditingController(text: '0');

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 440,
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'New Commission Config',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              _dialogDropdown('Transaction Type', txTypeCtrl, [
                'rental',
                'swap',
                'purchase',
              ]),
              const SizedBox(height: 16),
              _dialogField(
                'Percentage (%)',
                pctCtrl,
                type: TextInputType.number,
              ),
              const SizedBox(height: 16),
              _dialogField('Flat Fee (₹)', feeCtrl, type: TextInputType.number),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () async {
                      final success = await _repository.createCommissionConfig({
                        'transaction_type': txTypeCtrl.text,
                        'percentage': double.tryParse(pctCtrl.text) ?? 0,
                        'flat_fee': double.tryParse(feeCtrl.text) ?? 0,
                      });
                      if (!ctx.mounted || !mounted) {
                        return;
                      }
                      if (success) {
                        Navigator.pop(ctx);
                        _loadData();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Create'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditConfigDialog(CommissionConfig c) {
    final pctCtrl = TextEditingController(text: c.percentage.toString());
    final feeCtrl = TextEditingController(text: c.flatFee.toString());

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 440,
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit Commission Config #${c.id}',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              _dialogField(
                'Percentage (%)',
                pctCtrl,
                type: TextInputType.number,
              ),
              const SizedBox(height: 16),
              _dialogField('Flat Fee (₹)', feeCtrl, type: TextInputType.number),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () async {
                      final success = await _repository
                          .updateCommissionConfig(c.id, {
                            'percentage': double.tryParse(pctCtrl.text),
                            'flat_fee': double.tryParse(feeCtrl.text),
                          });
                      if (!ctx.mounted || !mounted) {
                        return;
                      }
                      if (success) {
                        Navigator.pop(ctx);
                        _loadData();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dialogField(
    String label,
    TextEditingController ctrl, {
    TextInputType? type,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: type,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF1E293B),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _dialogDropdown(
    String label,
    TextEditingController ctrl,
    List<String> opts,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: ctrl.text,
              isExpanded: true,
              dropdownColor: const Color(0xFF1E293B),
              items: opts
                  .map(
                    (o) => DropdownMenuItem(
                      value: o,
                      child: Text(
                        o[0].toUpperCase() + o.substring(1),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => ctrl.text = v ?? ''),
            ),
          ),
        ),
      ],
    );
  }
}
