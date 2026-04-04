import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../data/models/fraud_risk.dart';
import '../data/models/duplicate_account.dart';
import '../data/models/blacklist_entry.dart';
import '../provider/fraud_provider.dart';
import '../../../core/widgets/admin_ui_components.dart';

class FraudRiskView extends ConsumerStatefulWidget {
  const FraudRiskView({super.key});

  @override
  ConsumerState<FraudRiskView> createState() => _FraudRiskViewState();
}

class _FraudRiskViewState extends ConsumerState<FraudRiskView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _panController = TextEditingController();
  final _panNameController = TextEditingController();
  final _gstController = TextEditingController();
  final _gstBusinessController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _panController.dispose();
    _panNameController.dispose();
    _gstController.dispose();
    _gstBusinessController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(fraudProvider);

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.blue));
    }

    return Column(
      children: [
        _buildHeader(state),
        const SizedBox(height: 8),
        _buildTabs(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildHighRiskTab(state),
              _buildDuplicatesTab(state),
              _buildBlacklistTab(state),
              _buildFingerprintsTab(state),
              _buildVerificationTab(state),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(FraudState state) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, top: 24, right: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fraud Risk Monitoring',
            style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          Text(
            'Anomaly detection, duplicate account verification, and security controls',
            style: GoogleFonts.inter(fontSize: 14, color: Colors.white54),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        dividerColor: Colors.transparent,
        indicatorColor: Colors.blue,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white38,
        labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 12),
        tabs: const [
          Tab(text: 'High Risk Users', icon: Icon(Icons.warning_amber_outlined, size: 20)),
          Tab(text: 'Duplicate Accounts', icon: Icon(Icons.people_outline, size: 20)),
          Tab(text: 'Blacklist', icon: Icon(Icons.block_outlined, size: 20)),
          Tab(text: 'Device Fingerprints', icon: Icon(Icons.fingerprint_outlined, size: 20)),
          Tab(text: 'Verification', icon: Icon(Icons.fact_check_outlined, size: 20)),
        ],
      ),
    );
  }

  // ─── High Risk Users Tab ───────────────────────────────────────────

  Widget _buildHighRiskTab(FraudState state) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Master list
        Container(
          width: 380,
          margin: const EdgeInsets.only(left: 24, bottom: 24),
          child: ListView.builder(
            itemCount: state.highRiskUsers.length,
            itemBuilder: (context, idx) {
              final user = state.highRiskUsers[idx];
              final isSelected = state.selectedUserId == user.userId;
              return _buildUserTile(user, isSelected);
            },
          ),
        ),
        const SizedBox(width: 24),
        // Detail section
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 24, bottom: 24),
            child: state.selectedUserRisk != null
                ? _buildUserDetailPanel(state.selectedUserRisk!)
                : _buildEmptyDetail('Select a high-risk user to view scoring breakdown'),
          ),
        ),
      ],
    );
  }

  Widget _buildUserTile(FraudRisk user, bool isSelected) {
    final color = _riskColor(user.level);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AdvancedCard(
        padding: const EdgeInsets.all(16),
        child: InkWell(
          onTap: () => ref.read(fraudProvider.notifier).selectUser(user.userId),
          child: Row(
            children: [
              _buildMiniGauge(user.score, color),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.userName, style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                    _buildRiskBadge(user.level),
                  ],
                ),
              ),
              if (isSelected) const Icon(Icons.chevron_right, color: Colors.blue),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserDetailPanel(FraudRisk risk) {
    final color = _riskColor(risk.level);
    return AdvancedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(spacing: 16, runSpacing: 16, alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _buildBigGauge(risk.score, color),
              const SizedBox(width: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('User ID: ${risk.userId}', style: GoogleFonts.outfit(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  Text(risk.userName, style: GoogleFonts.inter(color: Colors.white70, fontSize: 16)),
                  Text('Last analysis updated: ${DateFormat('MMM d, HH:mm').format(risk.lastUpdated)}', style: GoogleFonts.inter(color: Colors.white38, fontSize: 12)),
                ],
              ),
              
              _buildActionButton('Suspend User', Colors.red, () {}),
              const SizedBox(width: 12),
              _buildActionButton('Whitelist', Colors.green, () {}),
            ],
          ),
          const SizedBox(height: 32),
          Text('Risk Breakdown Factors', style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...risk.factors.map((f) => _buildFactorRow(f.name, f.contribution.toString(), f.description)),
        ],
      ),
    );
  }

  Widget _buildFactorRow(String name, String value, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name.toUpperCase(), style: GoogleFonts.inter(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
              Text('+$value', style: GoogleFonts.inter(color: Colors.orange, fontWeight: FontWeight.bold)),
            ],
          ),
          if (desc.isNotEmpty)
            Text(desc, style: GoogleFonts.inter(color: Colors.white38, fontSize: 11)),
        ],
      ),
    );
  }

  // ─── Duplicates Tab ────────────────────────────────────────────────

  Widget _buildDuplicatesTab(FraudState state) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: AdvancedCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Suspected Duplicate Accounts', style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            AdvancedTable(
              columns: const ['Primary ID', 'Suspected ID', 'Confidence', 'Matching IP', 'Matching Phone', 'Status', 'Actions'],
              rows: state.duplicateAccounts.map((d) {
                return [
                  _whiteText(d.primaryUserId.toString()),
                  _whiteText(d.suspectedDuplicateUserId.toString()),
                  _percentBadge(d.overallConfidence),
                  _boolIcon(d.matchingIp),
                  _boolIcon(d.matchingPhone),
                  StatusBadge(status: d.status),
                  _buildActionMenu(d.id),
                ];
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Blacklist Tab ─────────────────────────────────────────────────

  Widget _buildBlacklistTab(FraudState state) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: AdvancedCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(spacing: 16, runSpacing: 16, alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('Global Blacklist Entries', style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                
                ElevatedButton.icon(
                  onPressed: () => _showAddBlacklistDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('New Entry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            AdvancedTable(
              columns: const ['Type', 'Value', 'Reason', 'Date Added', 'Actions'],
              rows: state.blacklist.map((b) {
                return [
                  _whiteText(b.type.toUpperCase()),
                  Text(b.value, style: GoogleFonts.firaCode(color: Colors.white, fontSize: 12)),
                  _whiteText(b.reason),
                  _whiteText(DateFormat('MMM d, yyyy').format(b.createdAt)),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                    onPressed: () => ref.read(fraudProvider.notifier).removeFromBlacklist(b.id),
                  ),
                ];
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Fingerprints Tab ──────────────────────────────────────────────

  Widget _buildFingerprintsTab(FraudState state) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: AdvancedCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(spacing: 16, runSpacing: 16, alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('Device Fingerprints', style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      value: state.showSuspiciousOnly,
                      onChanged: (v) => ref.read(fraudProvider.notifier).refreshDeviceFingerprints(suspiciousOnly: v),
                      activeTrackColor: Colors.blue.withValues(alpha: 0.5),
                      activeThumbColor: Colors.blue,
                    ),
                    Text('Suspicious Only', style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            AdvancedTable(
              columns: const ['User ID', 'Device Type', 'OS', 'Fingerprint Hash', 'Risk Score', 'First Seen'],
              rows: state.deviceFingerprints.map((f) {
                return [
                  _whiteText(f['id']?.toString() ?? 'N/A'),
                  _whiteText(f['type']?.toString().toUpperCase() ?? 'UNKNOWN'),
                  _whiteText(f['os']?.toString() ?? 'N/A'),
                  Text(f['hash']?.toString().substring(0, 8) ?? 'N/A', style: GoogleFonts.firaCode(color: Colors.blue.shade200, fontSize: 11)),
                  _percentBadge(f['risk_score'] ?? 0),
                  _whiteText(f['first_seen'] ?? 'N/A'),
                ];
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Verification Tab ────────────────────────────────────────────────

  Widget _buildVerificationTab(FraudState state) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildVerificationForm('PAN Verification', Icons.badge_outlined, 'Enter PAN Number', 'Enter Full Name', _panController, _panNameController, () {
            ref.read(fraudProvider.notifier).verifyPan(panNumber: _panController.text, name: _panNameController.text);
          })),
          const SizedBox(width: 24),
          Expanded(child: _buildVerificationForm('GST Verification', Icons.business_outlined, 'Enter GST Number', 'Enter Business Name', _gstController, _gstBusinessController, () {
            ref.read(fraudProvider.notifier).verifyGst(gstNumber: _gstController.text, businessName: _gstBusinessController.text);
          })),
          const SizedBox(width: 24),
          Expanded(
            child: AdvancedCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Phone Verification', style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  AdminTextField(controller: _phoneController, label: 'Phone Number', hint: 'e.g. +91 98XXX XXXXX', icon: Icons.phone_android_outlined),
                  const SizedBox(height: 24),
                  AdminButton(label: 'Check Risk', onPressed: () {
                    ref.read(fraudProvider.notifier).verifyPhone(phoneNumber: _phoneController.text);
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationForm(String title, IconData icon, String label1, String label2, TextEditingController c1, TextEditingController c2, VoidCallback onVerify) {
    return AdvancedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          AdminTextField(controller: c1, label: label1, hint: 'Value...', icon: icon),
          const SizedBox(height: 16),
          AdminTextField(controller: c2, label: label2, hint: 'Reference...', icon: Icons.person_outline),
          const SizedBox(height: 24),
          AdminButton(label: 'Verify Now', onPressed: onVerify),
        ],
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────

  Widget _buildMiniGauge(int value, Color color) {
    return SizedBox(
      width: 40,
      height: 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: (value / 100).clamp(0.0, 1.0),
            strokeWidth: 4,
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation(color),
          ),
          Text(value.toString(), style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildBigGauge(int value, Color color) {
    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: (value / 100).clamp(0.0, 1.0),
            strokeWidth: 8,
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation(color),
          ),
          Text(value.toString(), style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildRiskBadge(String level) {
    final color = _riskColor(level);
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(4)),
      child: Text(level.toUpperCase(), style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: color)),
    );
  }

  Widget _percentBadge(dynamic val) {
    final v = val is num ? val.toDouble() : 0.0;
    final color = v > 70 ? Colors.red : (v > 40 ? Colors.orange : Colors.green);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(4)),
      child: Text('${v.toStringAsFixed(0)}%', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
    );
  }

  Widget _boolIcon(dynamic val) => Icon(
    val == true ? Icons.check_circle_outline : Icons.cancel_outlined,
    color: val == true ? Colors.red : Colors.green.shade300,
    size: 18,
  );

  Widget _buildActionButton(String label, Color color, VoidCallback onPressed) => ElevatedButton(
    onPressed: onPressed,
    style: ElevatedButton.styleFrom(
      backgroundColor: color.withValues(alpha: 0.12),
      foregroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: color.withValues(alpha: 0.3))),
    ),
    child: Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
  );

  Widget _buildActionMenu(int id) => PopupMenuButton(
    icon: const Icon(Icons.more_vert, color: Colors.white38),
    itemBuilder: (context) => [
      const PopupMenuItem(value: 'block', child: Text('Block Both Accounts')),
      const PopupMenuItem(value: 'suspend', child: Text('Suspend Suspicious')),
      const PopupMenuItem(value: 'whitelist', child: Text('Manual Whitelist')),
    ],
    onSelected: (v) => ref.read(fraudProvider.notifier).handleDuplicateAccount(id, action: v),
  );

  Widget _buildEmptyDetail(String msg) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.shield_outlined, size: 64, color: Colors.white.withValues(alpha: 0.1)),
        const SizedBox(height: 16),
        Text(msg, style: GoogleFonts.inter(color: Colors.white38)),
      ],
    ),
  );

  Widget _whiteText(String text) => Text(text, style: GoogleFonts.inter(color: Colors.white70, fontSize: 13));

  Color _riskColor(String level) {
    switch (level.toLowerCase()) {
      case 'critical': return Colors.red;
      case 'high': return Colors.orange;
      case 'medium': return Colors.amber;
      case 'low': return Colors.green.shade300;
      default: return Colors.grey;
    }
  }

  void _showAddBlacklistDialog() {
    String selectedType = 'ip';
    final valueController = TextEditingController();
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: Text('Add to Blacklist', style: GoogleFonts.outfit(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                dropdownColor: const Color(0xFF1E293B),
                style: const TextStyle(color: Colors.white),
                value: selectedType,
                items: const [
                  DropdownMenuItem(value: 'ip', child: Text('IP Address')),
                  DropdownMenuItem(value: 'device', child: Text('Device ID')),
                  DropdownMenuItem(value: 'email', child: Text('Email')),
                  DropdownMenuItem(value: 'phone', child: Text('Phone')),
                ],
                onChanged: (v) => setDialogState(() => selectedType = v!),
                decoration: const InputDecoration(labelText: 'Type'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: valueController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Value (e.g. 192.168.1.1)'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Reason'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                ref.read(fraudProvider.notifier).addToBlacklist(
                  type: selectedType,
                  value: valueController.text,
                  reason: reasonController.text,
                );
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}
