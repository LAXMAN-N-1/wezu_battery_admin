import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/models/settings_models.dart';
import '../data/repositories/settings_repository.dart';

class FeatureFlagsView extends StatefulWidget {
  const FeatureFlagsView({super.key});
  @override State<FeatureFlagsView> createState() => _FeatureFlagsViewState();
}

class _FeatureFlagsViewState extends State<FeatureFlagsView> {
  final SettingsRepository _repo = SettingsRepository();
  List<FeatureFlagItem> _flags = [];
  bool _isLoading = true;

  @override void initState() { super.initState(); _loadData(); }
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try { _flags = await _repo.getFeatureFlags(); setState(() => _isLoading = false); }
    catch (e) { setState(() => _isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Feature Flags', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
      const SizedBox(height: 4),
      Text('Toggle experimental features and platform modules in real-time', style: GoogleFonts.inter(color: Colors.white54, fontSize: 14)),
      const SizedBox(height: 32),
      _isLoading ? const Center(child: CircularProgressIndicator())
          : _flags.isEmpty ? const Text('No feature flags found', style: TextStyle(color: Colors.white54))
          : _buildFlagsList(),
    ]));
  }

  Widget _buildFlagsList() {
    return Container(padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ..._flags.map((f) => _flagRow(f)),
      ]));
  }

  Widget _flagRow(FeatureFlagItem flag) {
    return Container(margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(12), border: Border.all(color: flag.isEnabled ? Colors.green.withValues(alpha: 0.2) : Colors.transparent)),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: (flag.isEnabled ? Colors.green : Colors.grey).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(flag.isEnabled ? Icons.toggle_on : Icons.toggle_off, color: flag.isEnabled ? Colors.green : Colors.grey, size: 24)),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(flag.name, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(width: 8),
            Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(4)),
              child: Text(flag.key, style: GoogleFonts.robotoMono(fontSize: 10, color: Colors.white38))),
          ]),
          if (flag.description != null) ...[
            const SizedBox(height: 4), Text(flag.description!, style: GoogleFonts.inter(fontSize: 13, color: Colors.white54)),
          ],
        ])),
        Switch(value: flag.isEnabled, activeThumbColor: Colors.green, onChanged: (val) async {
          await _repo.toggleFeatureFlag(flag.id, val); _loadData();
        }),
      ]));
  }
}
