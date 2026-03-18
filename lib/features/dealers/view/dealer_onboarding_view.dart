import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/widgets/admin_ui_components.dart';
import '../data/models/dealer_application.dart';
import '../data/repositories/dealer_repository.dart';

class DealerOnboardingView extends StatefulWidget {
  const DealerOnboardingView({super.key});

  @override
  State<DealerOnboardingView> createState() => _DealerOnboardingViewState();
}

class _DealerOnboardingViewState extends State<DealerOnboardingView> {
  final DealerRepository _repository = DealerRepository();
  List<DealerApplication> _applications = [];
  bool _isLoading = true;
  String _selectedStage = 'SUBMITTED';

  final List<String> _stages = [
    'SUBMITTED', 'KYC_PENDING', 'KYC_SUBMITTED', 'REVIEW_PENDING',
    'FIELD_VISIT_SCHEDULED', 'FIELD_VISIT_COMPLETED', 'REJECTED', 'APPROVED'
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final apps = await _repository.getApplications(stage: _selectedStage);
    setState(() {
      _applications = apps;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Registration Requests', style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text('Manage 8-stage dealer onboarding queue and stage transitions.', style: GoogleFonts.inter(fontSize: 16, color: Colors.white54)),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh Queue'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E293B)),
              ),
            ],
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 32),

          // Stage Selector
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _stages.map((stage) {
                final isSelected = _selectedStage == stage;
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: FilterChip(
                    label: Text(stage.replaceAll('_', ' ')),
                    selected: isSelected,
                    onSelected: (val) {
                      setState(() => _selectedStage = stage);
                      _loadData();
                    },
                    backgroundColor: const Color(0xFF1E293B),
                    selectedColor: const Color(0xFF3B82F6),
                    labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.white70),
                  ),
                );
              }).toList(),
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
          const SizedBox(height: 24),

          // Applications List
          Expanded(
            child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _applications.isEmpty
                  ? Center(child: Text('No applications in this stage.', style: GoogleFonts.inter(color: Colors.white54)))
                  : ListView.builder(
                      itemCount: _applications.length,
                      itemBuilder: (context, index) {
                        final app = _applications[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: AdvancedCard(
                            child: ListTile(
                            title: Text(app.businessName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                            subtitle: Text('Submitted on: ${app.createdAt.toString().split(' ')[0]}', style: const TextStyle(color: Colors.white54)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                OutlinedButton(
                                  onPressed: () => _updateStage(app, 'REJECTED'),
                                  style: OutlinedButton.styleFrom(foregroundColor: Color(0xFFEF4444)),
                                  child: const Text('Reject'),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton(
                                  onPressed: () => _showNextStageDialog(app),
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6)),
                                  child: const Text('Move to Next Stage'),
                                ),
                              ],
                            ),
                            ),
                          ),
                        ).animate().fadeIn(duration: 300.ms, delay: (index * 50).ms);
                      },
                    ),
          ),
        ],
      ),
    );
  }

  void _updateStage(DealerApplication app, String stage) async {
    final ok = await _repository.updateApplicationStage(app.id, stage);
    if (ok) _loadData();
  }

  void _showNextStageDialog(DealerApplication app) {
    int currentIndex = _stages.indexOf(app.currentStage);
    if (currentIndex >= _stages.length - 1) return;
    
    String nextStage = _stages[currentIndex + 1];
    if (nextStage == 'REJECTED') nextStage = _stages[currentIndex + 2];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text('Move to $nextStage', style: const TextStyle(color: Colors.white)),
        content: Text('Are you sure you want to move ${app.businessName} to the $nextStage stage?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              _updateStage(app, nextStage);
              Navigator.pop(ctx);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}
