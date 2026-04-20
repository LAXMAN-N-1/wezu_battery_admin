import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/models/notification_models.dart';
import '../data/repositories/notification_repository.dart';
import 'package:frontend_admin/core/utils/safe_state.dart';

class SmsEmailConfigView extends StatefulWidget {
  const SmsEmailConfigView({super.key});
  @override State<SmsEmailConfigView> createState() => _SmsEmailConfigViewState();
}

class _SmsEmailConfigViewState extends SafeState<SmsEmailConfigView> {
  final NotificationRepository _repo = NotificationRepository();
  List<NotificationConfig> _configs = [];
  bool _isLoading = true;

  @override void initState() { super.initState(); _loadData(); }
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try { _configs = await _repo.getConfigs(); if (mounted) setState(() => _isLoading = false); }
    catch (e) { if (mounted) setState(() => _isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('SMS & Email Configuration', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
      const SizedBox(height: 4),
      Text('Configure notification provider credentials', style: TextStyle(color: Colors.white54, fontSize: 14)),
      const SizedBox(height: 24),
      _isLoading ? const Center(child: CircularProgressIndicator())
          : Column(children: _configs.map(_buildConfigCard).toList()),
    ]));
  }

  Widget _buildConfigCard(NotificationConfig c) {
    final (icon, color) = _providerStyle(c.provider);
    return Container(margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.isActive ? color.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.06))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 24)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(c.displayName, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 4),
            Row(children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(6)),
                child: Text(c.channel.toUpperCase(), style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold))),
              const SizedBox(width: 8),
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(6)),
                child: Text(c.provider.toUpperCase(), style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold))),
            ]),
          ])),
          Column(children: [
            IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 18), onPressed: () => _showEditDialog(c)),
            Switch(value: c.isActive, activeThumbColor: Colors.green,
              onChanged: (val) async { await _repo.updateConfig(c.id, {'is_active': val}); _loadData(); }),
            Text(c.isActive ? 'Active' : 'Inactive', style: TextStyle(color: c.isActive ? Colors.green : Colors.white38, fontSize: 11)),
          ]),
        ]),
        const SizedBox(height: 16),
        Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(10)),
          child: Column(children: [
            _configRow('API Key', c.apiKey ?? '—'),
            if (c.senderId != null) _configRow('Sender ID', c.senderId!),
            _configRow('Last Tested', c.lastTestedAt != null ? _formatTs(c.lastTestedAt!) : 'Never'),
            if (c.testStatus != null) _configRow('Test Status', c.testStatus!.toUpperCase(),
              valueColor: c.testStatus == 'success' ? Colors.green : Colors.red),
          ])),
        const SizedBox(height: 14),
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          OutlinedButton.icon(onPressed: () => _testConfig(c.id), icon: const Icon(Icons.science, size: 16),
            label: const Text('Test Connection'), style: OutlinedButton.styleFrom(foregroundColor: Colors.blue,
              side: const BorderSide(color: Colors.blue), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)))),
        ]),
      ]));
  }

  Widget _configRow(String label, String value, {Color? valueColor}) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [
      SizedBox(width: 100, child: Text(label, style: TextStyle(color: Colors.white38, fontSize: 12))),
      Expanded(child: Text(value, style: GoogleFonts.robotoMono(color: valueColor ?? Colors.white70, fontSize: 12))),
    ]));
  }

  void _showEditDialog(NotificationConfig c) {
    final nameCtrl = TextEditingController(text: c.displayName);
    final keyCtrl = TextEditingController(text: c.apiKey);
    final senderCtrl = TextEditingController(text: c.senderId);
    bool isActive = c.isActive;

    showDialog(context: context, builder: (ctx) => StatefulBuilder(
      builder: (context, setModalState) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text('Configure ${c.provider.toUpperCase()} Integration', style: GoogleFonts.outfit(color: Colors.white)),
        content: SizedBox(width: 450, child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameCtrl, style: const TextStyle(color: Colors.white), decoration: _inputDeco('Display Name')),
          const SizedBox(height: 10),
          TextField(controller: keyCtrl, style: const TextStyle(color: Colors.white), decoration: _inputDeco('API/Secret Key (Keep secure)')),
          const SizedBox(height: 10),
          TextField(controller: senderCtrl, style: const TextStyle(color: Colors.white), decoration: _inputDeco('Sender ID (e.g. +1234567, no-reply@)')),
          const SizedBox(height: 16),
          Container(decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(10)), child: SwitchListTile(
            title: Text('Account Integration Active', style: TextStyle(color: Colors.white70, fontSize: 13)),
            value: isActive, activeThumbColor: Colors.green, inactiveTrackColor: Colors.white12,
            onChanged: (v) => setModalState(() => isActive = v),
          )),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: () async {
            await _repo.updateConfig(c.id, {
              'display_name': nameCtrl.text, 'api_key': keyCtrl.text, 'sender_id': senderCtrl.text, 'is_active': isActive
            });
            if (ctx.mounted) Navigator.pop(ctx); _loadData();
          }, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6)), child: const Text('Save Credentials')),
        ])));
  }

  InputDecoration _inputDeco(String label) => InputDecoration(labelText: label, labelStyle: const TextStyle(color: Colors.white38),
    filled: true, fillColor: Colors.white.withValues(alpha: 0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none));

  (IconData, Color) _providerStyle(String provider) {
    switch (provider) {
      case 'firebase': return (Icons.local_fire_department, Colors.orange);
      case 'twilio': return (Icons.sms, Colors.red);
      case 'sendgrid': return (Icons.email, Colors.blue);
      case 'smtp': return (Icons.mail_outline, Colors.grey);
      default: return (Icons.settings, Colors.blue);
    }
  }

  Future<void> _testConfig(int id) async {
    try { await _repo.testConfig(id); _loadData();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Test passed! ✓')));
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Test failed: $e'))); }
  }

  String _formatTs(String ts) {
    try { final dt = DateTime.parse(ts); final diff = DateTime.now().difference(dt);
      if (diff.inHours < 24) return '${diff.inHours}h ago'; return '${diff.inDays}d ago'; } catch (_) { return ts; }
  }
}
