import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/models/settings_models.dart';
import '../data/repositories/settings_repository.dart';

class GeneralSettingsView extends StatefulWidget {
  const GeneralSettingsView({super.key});
  @override State<GeneralSettingsView> createState() => _GeneralSettingsViewState();
}

class _GeneralSettingsViewState extends State<GeneralSettingsView> {
  final SettingsRepository _repo = SettingsRepository();
  Map<String, SystemConfigItem> _settings = {};
  bool _isLoading = true;

  @override void initState() { super.initState(); _loadData(); }
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try { _settings = await _repo.getGeneralSettings(); setState(() => _isLoading = false); }
    catch (e) { setState(() => _isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('General Settings', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 4),
          Text('Manage application-wide system configurations', style: TextStyle(color: Colors.white54, fontSize: 14)),
        ])),
        ElevatedButton.icon(
          onPressed: _showCreateDialog, icon: const Icon(Icons.add, size: 18), label: const Text('New Config'),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6), foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))),
      ]),
      const SizedBox(height: 32),
      _isLoading ? const Center(child: CircularProgressIndicator())
          : _buildSettingsContent(),
    ]));
  }

  Widget _buildSettingsContent() {
    final appConfigs = _settings.values.where((s) => s.key.startsWith('app_')).toList();
    final paymentConfigs = _settings.values.where((s) => s.key.startsWith('payment_')).toList();
    final notificationConfigs = _settings.values.where((s) => s.key.startsWith('notification_')).toList();
    final otherConfigs = _settings.values.where((s) => !s.key.startsWith('app_') && !s.key.startsWith('payment_') && !s.key.startsWith('notification_')).toList();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (appConfigs.isNotEmpty) _configSection('Platform Configuration', Icons.devices, appConfigs),
      if (paymentConfigs.isNotEmpty) _configSection('Payment & Billing', Icons.payments, paymentConfigs),
      if (notificationConfigs.isNotEmpty) _configSection('Notification Preferences', Icons.notifications, notificationConfigs),
      if (otherConfigs.isNotEmpty) _configSection('Other Settings', Icons.settings, otherConfigs),
    ]);
  }

  Widget _configSection(String title, IconData icon, List<SystemConfigItem> configs) {
    return Container(margin: const EdgeInsets.only(bottom: 24), padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: Colors.blue, size: 24), const SizedBox(width: 12),
          Text(title, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        ]),
        const SizedBox(height: 24),
        ...configs.map((c) => _configRow(c)),
      ]));
  }

  Widget _configRow(SystemConfigItem config) {
    return Padding(padding: const EdgeInsets.only(bottom: 20), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(config.key.toUpperCase(), style: GoogleFonts.robotoMono(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
        if (config.description != null) ...[
          const SizedBox(height: 4), Text(config.description!, style: TextStyle(fontSize: 12, color: Colors.white54)),
        ],
      ])),
      const SizedBox(width: 24),
      Expanded(flex: 2, child: _renderInputForValue(config)),
    ]));
  }

  Widget _renderInputForValue(SystemConfigItem config) {
    if (config.value == 'true' || config.value == 'false') {
      return Align(alignment: Alignment.centerLeft, child: Switch(value: config.value == 'true', activeThumbColor: Colors.blue, onChanged: (val) {
        _repo.updateGeneralSetting(config.id, val.toString()); _loadData();
      }));
    }
    final ctrl = TextEditingController(text: config.value);
    return Row(children: [
      Expanded(child: TextField(controller: ctrl, style: GoogleFonts.robotoMono(color: Colors.white, fontSize: 13),
        decoration: InputDecoration(isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          filled: true, fillColor: Colors.white.withValues(alpha: 0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none)))),
      const SizedBox(width: 8),
      IconButton(icon: const Icon(Icons.save, color: Colors.blue, size: 18), onPressed: () async {
        await _repo.updateGeneralSetting(config.id, ctrl.text); _loadData();
      }),
    ]);
  }

  void _showCreateDialog() {
    final keyCtrl = TextEditingController();
    final valCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF1E293B), title: Text('New Configuration', style: GoogleFonts.outfit(color: Colors.white)),
      content: SizedBox(width: 400, child: Column(mainAxisSize: MainAxisSize.min, children: [
        _field(keyCtrl, 'Key (e.g., config_name)'), const SizedBox(height: 10),
        _field(valCtrl, 'Value'), const SizedBox(height: 10),
        _field(descCtrl, 'Description'),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(onPressed: () async {
          await _repo.createGeneralSetting(keyCtrl.text, valCtrl.text, desc: descCtrl.text);
          if (ctx.mounted) Navigator.pop(ctx); _loadData();
        }, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6)), child: const Text('Create')),
      ]));
  }
  Widget _field(TextEditingController ctrl, String label) => TextField(controller: ctrl, style: const TextStyle(color: Colors.white), decoration: InputDecoration(labelText: label, labelStyle: const TextStyle(color: Colors.white38), filled: true, fillColor: Colors.white.withValues(alpha: 0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)));
}
