import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/repositories/audit_repository.dart';

class SecuritySettingsView extends StatefulWidget {
  const SecuritySettingsView({super.key});
  @override State<SecuritySettingsView> createState() => _SecuritySettingsViewState();
}

class _SecuritySettingsViewState extends State<SecuritySettingsView> {
  final AuditRepository _repo = AuditRepository();
  Map<String, dynamic> _settings = {};
  bool _isLoading = true;

  @override void initState() { super.initState(); _loadData(); }
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try { _settings = await _repo.getSecuritySettings(); setState(() => _isLoading = false); }
    catch (e) { setState(() => _isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Platform Security Settings', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
      const SizedBox(height: 4),
      Text('Manage authentication policies and platform restrictions', style: GoogleFonts.inter(color: Colors.white54, fontSize: 14)),
      const SizedBox(height: 32),
      _isLoading ? const Center(child: CircularProgressIndicator())
          : _buildSettingsContent(),
    ]));
  }

  Widget _buildSettingsContent() {
    final twoFactor = _settings['two_factor_auth'] ?? {};
    final sessionMgmt = _settings['session_management'] ?? {};
    final loginSec = _settings['login_security'] ?? {};
    final ipWhite = _settings['ip_whitelist'] ?? {};

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _section('Authentication', Icons.vpn_key, [
        _toggleRow('Enforce Two-Factor Authentication (2FA)', 'Require all admin users to enable 2FA', twoFactor['enabled'] == true, (val) => _updateSetting('two_factor_enabled', val)),
        _infoRow('Password Policy', 'Min 8 chars, 1 uppercase, 1 special char'),
      ]),
      const SizedBox(height: 24),
      _section('Session Management', Icons.timer, [
        _numberRow('Session Timeout (Minutes)', sessionMgmt['timeout_minutes'] ?? 60, (val) => _updateSetting('session_timeout', val)),
        _infoRow('Max Concurrent Sessions', '${sessionMgmt['max_concurrent_sessions'] ?? 3} sessions'),
      ]),
      const SizedBox(height: 24),
      _section('Rate Limiting & Lockout', Icons.block, [
        _numberRow('Max Login Attempts', loginSec['max_attempts'] ?? 5, (val) => _updateSetting('max_login_attempts', val)),
        _infoRow('Account Lockout Duration', '${loginSec['lockout_duration_minutes'] ?? 30} minutes after failed attempts'),
      ]),
      const SizedBox(height: 24),
      _section('Network Security', Icons.wifi_tethering, [
        _toggleRow('Enable IP Whitelisting', 'Restrict admin portal access to specific IP ranges', ipWhite['enabled'] == true, null),
        _infoRow('Active Whitelist Subnets', '0 subnets configured (Requires setup)'),
      ]),
    ]);
  }

  Widget _section(String title, IconData icon, List<Widget> children) {
    return Container(padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: Colors.blue, size: 24), const SizedBox(width: 12),
          Text(title, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        ]),
        const SizedBox(height: 24),
        ...children,
      ]));
  }

  Widget _toggleRow(String title, String subtitle, bool value, Function(bool)? onChanged) {
    return Padding(padding: const EdgeInsets.only(bottom: 20), child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
        const SizedBox(height: 4), Text(subtitle, style: GoogleFonts.inter(fontSize: 13, color: Colors.white54)),
      ])),
      Switch(value: value, activeThumbColor: Colors.blue, onChanged: onChanged),
    ]));
  }

  Widget _infoRow(String title, String subtitle) {
    return Padding(padding: const EdgeInsets.only(bottom: 20), child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
        const SizedBox(height: 4), Text(subtitle, style: GoogleFonts.inter(fontSize: 13, color: Colors.white38)),
      ])),
      const Icon(Icons.info_outline, color: Colors.white24, size: 20),
    ]));
  }

  Widget _numberRow(String title, int value, Function(int) onChanged) {
    return Padding(padding: const EdgeInsets.only(bottom: 20), child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
      ])),
      Container(width: 100, padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8)),
        child: DropdownButtonHideUnderline(child: DropdownButton<int>(
          value: value, isExpanded: true, dropdownColor: const Color(0xFF1E293B), style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
          items: [5, 15, 30, 60, 120, 240, 480].map((v) => DropdownMenuItem(value: v, child: Text('$v'))).toList(),
          onChanged: (val) { if (val != null) onChanged(val); }))),
    ]));
  }

  Future<void> _updateSetting(String key, dynamic value) async {
    try { await _repo.updateSecuritySettings({key: value}); _loadData();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Setting updated successfully')));
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Update failed: $e'))); }
  }
}
