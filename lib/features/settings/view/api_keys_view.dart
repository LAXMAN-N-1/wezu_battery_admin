import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/models/settings_models.dart';
import '../data/repositories/settings_repository.dart';

class ApiKeysView extends StatefulWidget {
  const ApiKeysView({super.key});
  @override State<ApiKeysView> createState() => _ApiKeysViewState();
}

class _ApiKeysViewState extends State<ApiKeysView> {
  final SettingsRepository _repo = SettingsRepository();
  List<ApiKeyItem> _keys = [];
  bool _isLoading = true;

  @override void initState() { super.initState(); _loadData(); }
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try { _keys = await _repo.getApiKeys(); setState(() => _isLoading = false); }
    catch (e) { setState(() => _isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('API Keys', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 4),
          Text('Manage API keys for external services and integrations', style: GoogleFonts.inter(color: Colors.white54, fontSize: 14)),
        ])),
        ElevatedButton.icon(
          onPressed: _showCreateDialog, icon: const Icon(Icons.add, size: 18), label: const Text('Generate Key'),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6), foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))),
      ]),
      const SizedBox(height: 32),
      _isLoading ? const Center(child: CircularProgressIndicator())
          : _keys.isEmpty ? const Text('No API keys configured', style: TextStyle(color: Colors.white54))
          : Column(children: _keys.map((k) => _keyCard(k)).toList()),
    ]));
  }

  Widget _keyCard(ApiKeyItem key) {
    final (icon, color) = _getServiceIcon(key.serviceName);
    return Container(margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(16), border: Border.all(color: key.isActive ? Colors.white.withValues(alpha: 0.05) : Colors.red.withValues(alpha: 0.2))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 24)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(key.keyName, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(width: 12),
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: (key.environment == 'production' ? Colors.red : Colors.green).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                child: Text(key.environment.toUpperCase(), style: GoogleFonts.inter(color: key.environment == 'production' ? Colors.red : Colors.green, fontSize: 10, fontWeight: FontWeight.bold))),
            ]),
            const SizedBox(height: 4), Text(key.serviceName.toUpperCase(), style: GoogleFonts.inter(fontSize: 12, color: Colors.white38)),
          ])),
          Switch(value: key.isActive, activeThumbColor: Colors.green, onChanged: (val) async {
            await _repo.updateApiKey(key.id, isActive: val); _loadData();
          }),
        ]),
        const SizedBox(height: 20),
        Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(8)),
          child: Row(children: [
            Expanded(child: Text(key.keyValueMasked, style: GoogleFonts.robotoMono(fontSize: 14, color: Colors.white70, letterSpacing: 1.5))),
            IconButton(icon: const Icon(Icons.copy, size: 18, color: Colors.white54), onPressed: () {}),
            IconButton(icon: const Icon(Icons.visibility_off, size: 18, color: Colors.white54), onPressed: () {}),
          ])),
        const SizedBox(height: 16),
        Wrap(spacing: 16, runSpacing: 16, alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center,children: [
          Icon(Icons.history, size: 14, color: Colors.white38), const SizedBox(width: 6),
          Text(key.lastUsedAt != null ? 'Last used: ${_formatDate(key.lastUsedAt!)}' : 'Never used', style: GoogleFonts.inter(color: Colors.white38, fontSize: 12)),
          
          TextButton.icon(
            onPressed: () async { await _repo.deleteApiKey(key.id); _loadData(); },
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 16),
            label: const Text('Revoke Key', style: TextStyle(color: Colors.red))),
        ]),
      ]));
  }

  (IconData, Color) _getServiceIcon(String service) {
    switch (service.toLowerCase()) {
      case 'stripe': return (Icons.payment, Colors.blue);
      case 'google_maps': return (Icons.map, Colors.green);
      case 'sendgrid': return (Icons.email, Colors.blueAccent);
      case 'twilio': return (Icons.sms, Colors.redAccent);
      case 'aws': return (Icons.cloud, Colors.orange);
      default: return (Icons.api, Colors.purple);
    }
  }

  String _formatDate(String ts) {
    try { final dt = DateTime.parse(ts); return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}'; } catch (_) { return ts; }
  }

  void _showCreateDialog() {
    final svcCtrl = TextEditingController(text: 'stripe');
    final nameCtrl = TextEditingController();
    final valCtrl = TextEditingController();
    String env = 'development';
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF1E293B), title: Text('Generate API Key', style: GoogleFonts.outfit(color: Colors.white)),
      content: SizedBox(width: 450, child: Column(mainAxisSize: MainAxisSize.min, children: [
        _field(svcCtrl, 'Service Name (e.g. stripe, google_maps)'), const SizedBox(height: 10),
        _field(nameCtrl, 'Key Name (e.g. Stripe Prod Secret)'), const SizedBox(height: 10),
        _field(valCtrl, 'Key Value'),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(onPressed: () async {
          await _repo.createApiKey(serviceName: svcCtrl.text, keyName: nameCtrl.text, keyValue: valCtrl.text, environment: env);
          if (ctx.mounted) Navigator.pop(ctx); _loadData();
        }, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6)), child: const Text('Save Key')),
      ]));
  }

  Widget _field(TextEditingController ctrl, String label) => TextField(controller: ctrl, style: const TextStyle(color: Colors.white), decoration: InputDecoration(labelText: label, labelStyle: const TextStyle(color: Colors.white38), filled: true, fillColor: Colors.white.withValues(alpha: 0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)));
}
