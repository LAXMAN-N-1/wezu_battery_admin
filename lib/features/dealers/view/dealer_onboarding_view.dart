import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/admin_ui_components.dart';
import '../data/models/dealer_application.dart';
import '../data/repositories/dealer_repository.dart';
import 'package:frontend_admin/core/utils/safe_state.dart';

class DealerOnboardingView extends StatefulWidget {
  const DealerOnboardingView({super.key});

  @override
  State<DealerOnboardingView> createState() => _DealerOnboardingViewState();
}

class _DealerOnboardingViewState extends SafeState<DealerOnboardingView> {
  final DealerRepository _repository = DealerRepository();
  List<DealerApplication> _applications = [];
  Map<String, int> _stageCounts = {};
  bool _isLoading = true;
  String _selectedStage = 'SUBMITTED';

  final List<Map<String, dynamic>> _stages = [
    {'key': 'SUBMITTED', 'label': 'Submitted', 'icon': Icons.send_outlined, 'color': const Color(0xFF3B82F6)},
    {'key': 'KYC_PENDING', 'label': 'KYC Pending', 'icon': Icons.pending_outlined, 'color': const Color(0xFFF59E0B)},
    {'key': 'KYC_SUBMITTED', 'label': 'KYC Submitted', 'icon': Icons.upload_file_outlined, 'color': const Color(0xFF06B6D4)},
    {'key': 'REVIEW_PENDING', 'label': 'Under Review', 'icon': Icons.rate_review_outlined, 'color': const Color(0xFF8B5CF6)},
    {'key': 'FIELD_VISIT_SCHEDULED', 'label': 'Visit Scheduled', 'icon': Icons.calendar_month_outlined, 'color': const Color(0xFFF97316)},
    {'key': 'FIELD_VISIT_COMPLETED', 'label': 'Visit Done', 'icon': Icons.check_circle_outline, 'color': const Color(0xFF14B8A6)},
    {'key': 'APPROVED', 'label': 'Approved', 'icon': Icons.verified_outlined, 'color': const Color(0xFF22C55E)},
    {'key': 'REJECTED', 'label': 'Rejected', 'icon': Icons.cancel_outlined, 'color': const Color(0xFFEF4444)},
  ];

  @override
  void initState() {
    super.initState();
    _loadAllCounts();
    _loadData();
  }

  Future<void> _loadAllCounts() async {
    final futures = _stages.map((stage) =>
      _repository.getApplications(stage: stage['key']).then((apps) => MapEntry(stage['key'] as String, apps.length)),
    );
    final entries = await Future.wait(futures);
    if (mounted) setState(() => _stageCounts = Map.fromEntries(entries));
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final apps = await _repository.getApplications(stage: _selectedStage);
    setState(() { _applications = apps; _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final total = _stageCounts.values.fold<int>(0, (s, v) => s + v);
    final pending = (_stageCounts['SUBMITTED'] ?? 0) + (_stageCounts['KYC_PENDING'] ?? 0) + (_stageCounts['REVIEW_PENDING'] ?? 0);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'Registration Requests',
            subtitle: 'Manage the 8-stage dealer onboarding pipeline.',
            actionButton: Row(children: [
              IconButton(icon: const Icon(Icons.refresh, color: Colors.white70), onPressed: () { _loadAllCounts(); _loadData(); }),
            ]),
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 20),

          // Stats
          Row(
            children: [
              _buildStat('Total Apps', '$total', Icons.description_outlined, const Color(0xFF3B82F6)),
              const SizedBox(width: 12),
              _buildStat('Pending Review', '$pending', Icons.pending_outlined, const Color(0xFFF59E0B)),
              const SizedBox(width: 12),
              _buildStat('Approved', '${_stageCounts['APPROVED'] ?? 0}', Icons.verified_outlined, const Color(0xFF22C55E)),
              const SizedBox(width: 12),
              _buildStat('Rejected', '${_stageCounts['REJECTED'] ?? 0}', Icons.cancel_outlined, const Color(0xFFEF4444)),
            ],
          ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
          const SizedBox(height: 20),

          // Pipeline Stage Selector
          AdvancedCard(
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _stages.map((stage) {
                  final isSelected = _selectedStage == stage['key'];
                  final count = _stageCounts[stage['key']] ?? 0;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () { _selectedStage = stage['key']; _loadData(); },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? (stage['color'] as Color).withValues(alpha: 0.15) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isSelected ? (stage['color'] as Color).withValues(alpha: 0.4) : Colors.white12),
                        ),
                        child: Row(
                          children: [
                            Icon(stage['icon'] as IconData, size: 16, color: isSelected ? stage['color'] as Color : Colors.white38),
                            const SizedBox(width: 8),
                            Text(stage['label'] as String, style: TextStyle(color: isSelected ? Colors.white : Colors.white54, fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                            if (count > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: (stage['color'] as Color).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
                                child: Text('$count', style: TextStyle(color: stage['color'] as Color, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 150.ms),
          const SizedBox(height: 20),

          // Applications List
          Expanded(
            child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _applications.isEmpty
                ? Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.inbox_outlined, color: Colors.white24, size: 56),
                      const SizedBox(height: 12),
                      Text('No applications in ${_selectedStage.replaceAll('_', ' ')} stage.', style: const TextStyle(color: Colors.white54)),
                    ]),
                  )
                : ListView.builder(
                    itemCount: _applications.length,
                    itemBuilder: (context, index) {
                      final app = _applications[index];
                      final stageData = _stages.firstWhere((s) => s['key'] == app.currentStage, orElse: () => _stages[0]);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: AdvancedCard(
                          child: Row(
                            children: [
                              Container(
                                width: 48, height: 48,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: [(stageData['color'] as Color).withValues(alpha: 0.3), (stageData['color'] as Color).withValues(alpha: 0.1)]),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Center(child: Text(app.businessName[0], style: GoogleFonts.outfit(color: stageData['color'] as Color, fontWeight: FontWeight.bold, fontSize: 20))),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(app.businessName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                  const SizedBox(height: 4),
                                  Row(children: [
                                    Text('Dealer #${app.dealerId}', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                                    const SizedBox(width: 12),
                                    const Icon(Icons.schedule, color: Colors.white38, size: 12),
                                    const SizedBox(width: 4),
                                    Text(DateFormat('MMM dd, yyyy').format(app.createdAt), style: const TextStyle(color: Colors.white38, fontSize: 12)),
                                  ]),
                                ]),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: (stageData['color'] as Color).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  (stageData['label'] as String).toUpperCase(),
                                  style: TextStyle(color: stageData['color'] as Color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                ),
                              ),
                              const SizedBox(width: 16),
                              if (app.currentStage != 'APPROVED' && app.currentStage != 'REJECTED') ...[
                                OutlinedButton(
                                  onPressed: () => _updateStage(app, 'REJECTED'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFFEF4444),
                                    side: const BorderSide(color: Color(0xFFEF4444), width: 0.5),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  child: const Text('Reject', style: TextStyle(fontSize: 13)),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () => _showNextStageDialog(app),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF3B82F6),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  child: const Text('Advance →', style: TextStyle(fontSize: 13)),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ).animate().fadeIn(duration: 300.ms, delay: (index * 50).ms).slideX(begin: -0.03);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _updateStage(DealerApplication app, String stage) async {
    final ok = await _repository.updateApplicationStage(app.id, stage);
    if (ok) { _loadAllCounts(); _loadData(); }
  }

  void _showNextStageDialog(DealerApplication app) {
    final stageKeys = _stages.map((s) => s['key'] as String).toList();
    int currentIndex = stageKeys.indexOf(app.currentStage);
    if (currentIndex >= stageKeys.length - 1) return;

    String nextStage = stageKeys[currentIndex + 1];
    if (nextStage == 'REJECTED') nextStage = stageKeys[currentIndex + 2];
    final nextData = _stages.firstWhere((s) => s['key'] == nextStage);

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
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: (nextData['color'] as Color).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: Icon(nextData['icon'] as IconData, color: nextData['color'] as Color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Advance Application', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text(app.businessName, style: const TextStyle(color: Colors.white54)),
                ])),
              ]),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  StatusBadge(status: app.currentStage.replaceAll('_', ' ')),
                  const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Icon(Icons.arrow_forward, color: Colors.white38, size: 16)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: (nextData['color'] as Color).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                    child: Text(nextData['label'] as String, style: TextStyle(color: nextData['color'] as Color, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ]),
              ),
              const SizedBox(height: 28),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () { _updateStage(app, nextStage); Navigator.pop(ctx); },
                  style: ElevatedButton.styleFrom(backgroundColor: nextData['color'] as Color, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text('Confirm'),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: AdvancedCard(
        child: Row(children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 18)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            Text(title, style: TextStyle(color: Colors.white54, fontSize: 11)),
          ])),
        ]),
      ),
    );
  }
}
