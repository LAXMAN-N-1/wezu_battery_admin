import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../data/models/audit_models.dart';
import '../data/repositories/audit_repository.dart';
import 'widgets/audit_components.dart';

class SecuritySettingsView extends StatefulWidget {
  const SecuritySettingsView({super.key});
  @override
  State<SecuritySettingsView> createState() => _SecuritySettingsViewState();
}

class _SecuritySettingsViewState extends State<SecuritySettingsView> {
  final AuditRepository _repo = AuditRepository();
  SecuritySettings? _settings;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isDirty = false;

  // IP Whitelist inline form state
  final _ipController = TextEditingController();
  final _ipLabelController = TextEditingController();
  bool _showAddIpRow = false;

  // Current user IP
  static const String _currentIp = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _ipController.dispose();
    _ipLabelController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _isDirty = false; });
    try {
      final res = await _repo.getSecuritySettings();
      if (mounted) setState(() { _settings = res; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _markDirty() => setState(() => _isDirty = true);

  Future<void> _saveSettings() async {
    if (_settings == null) return;

    // Confirmation dialog before saving
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Apply Security Settings?',
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        content: Text(
          'Saving these settings will affect all active users immediately. Active sessions may be terminated depending on your changes.',
          style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Confirm & Save', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSaving = true);
    try {
      await _repo.updateSecuritySettings(_settings!.toJson());
      if (mounted) {
        setState(() { _isSaving = false; _isDirty = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 18),
                const SizedBox(width: 10),
                Text('Security settings updated successfully', style: GoogleFonts.inter()),
              ],
            ),
            backgroundColor: const Color(0xFF1E3A5F),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 32),
                    if (_settings != null) ...[
                      _buildPasswordPolicy(),
                      const SizedBox(height: 20),
                      _buildTwoFactor(),
                      const SizedBox(height: 20),
                      _buildSessionManagement(),
                      const SizedBox(height: 20),
                      _buildIpWhitelist(),
                      const SizedBox(height: 20),
                      _buildLoginControls(),
                      const SizedBox(height: 20),
                      _buildDangerZone(),
                    ],
                  ],
                ),
              ),
        StickySaveBar(
          isDirty: _isDirty,
          isLoading: _isSaving,
          onSave: _saveSettings,
          onDiscard: _loadData,
        ),
      ],
    );
  }

  // ─── Page Header ─────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Security Settings',
          style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 4),
        Text(
          'Platform-wide security configuration — password policy, 2FA, sessions, IP whitelist and login controls',
          style: GoogleFonts.inter(color: Colors.white54, fontSize: 14),
        ),
      ],
    ).animate().fadeIn().slideY(begin: -0.05);
  }

  // ─── Section wrapper ──────────────────────────────────────────────────────
  Widget _section(String title, String subtitle, IconData icon, Color iconColor, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text(subtitle, style: GoogleFonts.inter(color: Colors.white38, fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Divider(color: Colors.white.withValues(alpha: 0.06), height: 1),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05);
  }

  // ─── Section A: Password Policy ───────────────────────────────────────────
  Widget _buildPasswordPolicy() {
    final p = _settings!.passwordPolicy;
    return _section(
      'Password Policy',
      'Define password complexity and rotation requirements',
      Icons.password_rounded,
      Colors.blueAccent,
      [
        _sliderRow(
          'Minimum Length',
          'Characters required in password',
          p.minLength.toDouble(),
          6, 20,
          (v) => setState(() {
            _settings = _settings!.copyWith(passwordPolicy: p.copyWith(minLength: v.round()));
            _markDirty();
          }),
          valueLabel: '${p.minLength} chars',
        ),
        _toggleRow(
          'Require Uppercase Letter',
          'At least one uppercase character (A–Z)',
          p.requireUppercase,
          (v) => setState(() {
            _settings = _settings!.copyWith(passwordPolicy: p.copyWith(requireUppercase: v));
            _markDirty();
          }),
        ),
        _toggleRow(
          'Require Number',
          'At least one numeric digit (0–9)',
          p.requireNumbers,
          (v) => setState(() {
            _settings = _settings!.copyWith(passwordPolicy: p.copyWith(requireNumbers: v));
            _markDirty();
          }),
        ),
        _toggleRow(
          'Require Special Character',
          'e.g., ! @ # \$ % ^ & *',
          p.requireSpecial,
          (v) => setState(() {
            _settings = _settings!.copyWith(passwordPolicy: p.copyWith(requireSpecial: v));
            _markDirty();
          }),
        ),
        _dropdownRow(
          'Password Expiry',
          'How often users must reset their password',
          _expiryLabel(p.expiryDays),
          ['Never', 'Every 30 Days', 'Every 60 Days', 'Every 90 Days'],
          (v) => setState(() {
            final days = _expiryDays(v!);
            _settings = _settings!.copyWith(passwordPolicy: p.copyWith(expiryDays: days));
            _markDirty();
          }),
        ),
        _stepperRow(
          'Prevent Reuse (Last N Passwords)',
          'Blocks users from reusing their previous passwords',
          3,
          0, 12,
          (v) => _markDirty(),
        ),
      ],
    );
  }

  String _expiryLabel(int days) {
    if (days == 0) return 'Never';
    if (days == 30) return 'Every 30 Days';
    if (days == 60) return 'Every 60 Days';
    return 'Every 90 Days';
  }

  int _expiryDays(String label) {
    if (label == 'Every 30 Days') return 30;
    if (label == 'Every 60 Days') return 60;
    if (label == 'Every 90 Days') return 90;
    return 0;
  }

  // ─── Section B: Two-Factor Authentication ─────────────────────────────────
  Widget _buildTwoFactor() {
    final t = _settings!.twoFactor;
    return _section(
      'Two-Factor Authentication (2FA)',
      'Configure multi-factor auth requirements per role',
      Icons.security_rounded,
      Colors.purpleAccent,
      [
        _toggleRow(
          'Enforce 2FA for Super Admins',
          'Recommended: always ON for highest-privilege accounts',
          t.enforceSuperAdmin,
          (v) {
            if (!v) {
              _show2FAWarning();
            }
            setState(() {
              _settings = _settings!.copyWith(twoFactor: t.copyWith(enforceSuperAdmin: v));
              _markDirty();
            });
          },
          warningIfOff: true,
        ),
        _toggleRow(
          'Enforce 2FA for All Admins',
          'Require 2FA for all users with Admin role',
          t.enforceAllAdmin,
          (v) => setState(() {
            _settings = _settings!.copyWith(twoFactor: t.copyWith(enforceAllAdmin: v));
            _markDirty();
          }),
        ),
        _toggleRow(
          'Enforce 2FA for Dealers',
          'Require 2FA for all dealer-role accounts',
          t.enabled,
          (v) => setState(() {
            _settings = _settings!.copyWith(twoFactor: t.copyWith(enabled: v));
            _markDirty();
          }),
        ),
        const SizedBox(height: 4),
        Builder(
          builder: (context) {
            final isAny2FAEnforced = t.enforceSuperAdmin || t.enforceAllAdmin || t.enabled;
            return Opacity(
              opacity: isAny2FAEnforced ? 1.0 : 0.4,
              child: AbsorbPointer(
                absorbing: !isAny2FAEnforced,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Allowed 2FA Methods', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                    const SizedBox(height: 10),
                    _checkboxRow('SMS OTP', t.allowSMS, (v) => setState(() {
                      _settings = _settings!.copyWith(twoFactor: t.copyWith(allowSMS: v ?? false));
                      _markDirty();
                    })),
                    _checkboxRow('Email OTP', t.allowEmail, (v) => setState(() {
                      _settings = _settings!.copyWith(twoFactor: t.copyWith(allowEmail: v ?? false));
                      _markDirty();
                    })),
                    _checkboxRow('Authenticator App (TOTP)', t.allowTOTP, (v) => setState(() {
                      _settings = _settings!.copyWith(twoFactor: t.copyWith(allowTOTP: v ?? false));
                      _markDirty();
                    })),
                    if (!isAny2FAEnforced)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Enforce 2FA for a role above to enable method selection',
                          style: GoogleFonts.inter(color: Colors.orangeAccent, fontSize: 11, fontWeight: FontWeight.w500),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }
        ),
        const SizedBox(height: 12),
        _dropdownRow(
          '2FA Grace Period for New Users',
          'How long new users have before 2FA is enforced',
          '7 Days',
          ['None', '7 Days', '14 Days'],
          (v) => _markDirty(),
        ),
      ],
    );
  }

  void _show2FAWarning() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 18),
            const SizedBox(width: 10),
            Text('Disabling 2FA for Super Admins is a security risk!', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ],
        ),
        backgroundColor: Colors.orange.shade900,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ─── Section C: Session Management ────────────────────────────────────────
  Widget _buildSessionManagement() {
    final s = _settings!.sessionMgmt;
    return _section(
      'Session Management',
      'Control active session duration and concurrency',
      Icons.timer_outlined,
      Colors.tealAccent,
      [
        _dropdownRow(
          'Admin Session Timeout (Inactivity)',
          'Auto-logout after this period of inactivity',
          _timeoutLabel(s.timeoutMinutes),
          ['15 minutes', '30 minutes', '1 hour', '4 hours', 'Never'],
          (v) => setState(() {
            _settings = _settings!.copyWith(sessionMgmt: s.copyWith(timeoutMinutes: _timeoutMinutes(v!)));
            _markDirty();
          }),
        ),
        _stepperRow(
          'Max Concurrent Sessions',
          'How many simultaneous logins are allowed per account',
          s.maxConcurrentSessions,
          1, 10,
          (v) => setState(() {
            _settings = _settings!.copyWith(sessionMgmt: s.copyWith(maxConcurrentSessions: v));
            _markDirty();
          }),
        ),
        _dropdownRow(
          'Remember Me Duration',
          'How long the "remember me" cookie persists',
          '7 Days',
          ['7 Days', '14 Days', '30 Days', 'Disabled'],
          (v) => _markDirty(),
        ),
        _toggleRow(
          'Notify on New Session',
          'Alert users when a new session is started on their account',
          s.notifyNewSession,
          (v) => setState(() {
            _settings = _settings!.copyWith(sessionMgmt: s.copyWith(notifyNewSession: v));
            _markDirty();
          }),
        ),
        const SizedBox(height: 8),
        _buildForceLogoutButton(),
      ],
    );
  }

  String _timeoutLabel(int mins) {
    if (mins == 15) return '15 minutes';
    if (mins == 30) return '30 minutes';
    if (mins == 60) return '1 hour';
    if (mins == 240) return '4 hours';
    return 'Never';
  }

  int _timeoutMinutes(String label) {
    if (label == '15 minutes') return 15;
    if (label == '30 minutes') return 30;
    if (label == '1 hour') return 60;
    if (label == '4 hours') return 240;
    return 9999;
  }

  Widget _buildForceLogoutButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.logout, color: Colors.redAccent, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Force Log Out All Admins', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.redAccent)),
                Text('Immediately invalidates all active admin sessions across the platform', style: GoogleFonts.inter(color: Colors.white38, fontSize: 12)),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: _showForceLogoutDialog,
            icon: const Icon(Icons.warning_amber_rounded, size: 14),
            label: Text('Force Logout', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700)),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.redAccent,
              side: const BorderSide(color: Colors.redAccent),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  void _showForceLogoutDialog() {
    final controller = TextEditingController();
    bool canConfirm = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setLocal) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.redAccent, width: 1.5),
          ),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 24),
              const SizedBox(width: 10),
              Text('Force Logout All Admins', style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.25)),
                ),
                child: Text(
                  'This will immediately terminate ALL active admin sessions. Every logged-in admin will be forcibly signed out and must log in again.',
                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Type "FORCE OUT" to confirm:',
                style: GoogleFonts.inter(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                autofocus: true,
                style: GoogleFonts.robotoMono(color: Colors.white, fontSize: 14, letterSpacing: 1.5),
                onChanged: (v) => setLocal(() => canConfirm = v == 'FORCE OUT'),
                decoration: InputDecoration(
                  hintText: 'FORCE OUT',
                  hintStyle: GoogleFonts.robotoMono(color: Colors.white24, fontSize: 14),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.06),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: canConfirm ? Colors.redAccent : Colors.white12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: canConfirm ? Colors.redAccent : Colors.white12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: canConfirm ? Colors.redAccent : Colors.blueAccent, width: 2),
                  ),
                  suffixIcon: canConfirm
                      ? const Icon(Icons.check_circle, color: Colors.redAccent)
                      : null,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: GoogleFonts.inter(color: Colors.white54)),
            ),
            ElevatedButton.icon(
              onPressed: canConfirm
                  ? () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.logout, color: Colors.white, size: 18),
                              const SizedBox(width: 10),
                              Text('All admin sessions terminated', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                            ],
                          ),
                          backgroundColor: Colors.redAccent.shade700,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                    }
                  : null,
              icon: const Icon(Icons.logout, size: 14),
              label: Text('Force Log Out All', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: canConfirm ? Colors.redAccent : Colors.grey.shade800,
                disabledBackgroundColor: Colors.grey.shade800,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        );
      }),
    );
  }

  // ─── Section D: IP Whitelist ──────────────────────────────────────────────
  Widget _buildIpWhitelist() {
    final ip = _settings!.ipWhitelist;
    return _section(
      'IP Whitelist',
      'Restrict admin access to specific IP addresses or CIDR ranges',
      Icons.lan_outlined,
      Colors.orangeAccent,
      [
        _toggleRow(
          'Enable IP Whitelist',
          'Only listed IPs can access the admin portal',
          ip.enabled,
          (v) {
            if (v) _showIpWarning();
            setState(() {
              _settings = _settings!.copyWith(ipWhitelist: ip.copyWith(enabled: v));
              _markDirty();
            });
          },
        ),
        if (ip.enabled) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orangeAccent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Enabling IP whitelist restricts admin access to listed IPs only. Ensure your current IP is in the list before saving or you will be locked out.',
                    style: GoogleFonts.inter(color: Colors.orangeAccent, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
        // Current IP quick-add
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
          ),
          child: Row(
            children: [
              const Icon(Icons.my_location, color: Colors.white38, size: 16),
              const SizedBox(width: 10),
              Text('Your current IP: ', style: GoogleFonts.inter(color: Colors.white54, fontSize: 13)),
              Text(_currentIp, style: GoogleFonts.robotoMono(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  if (!ip.whitelistedIps.contains(_currentIp)) {
                    setState(() {
                      final newList = [...ip.whitelistedIps, _currentIp];
                      _settings = _settings!.copyWith(ipWhitelist: ip.copyWith(whitelistedIps: newList));
                      _markDirty();
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$_currentIp added to whitelist', style: GoogleFonts.inter()),
                        backgroundColor: const Color(0xFF1E3A5F),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.add_circle_outline, size: 14),
                label: Text('Add My IP', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700)),
                style: TextButton.styleFrom(foregroundColor: Colors.blueAccent),
              ),
            ],
          ),
        ),
        // Whitelisted IPs table
        if (ip.whitelistedIps.isNotEmpty) ...[
          Row(
            children: [
              Expanded(flex: 3, child: Text('IP ADDRESS', style: GoogleFonts.inter(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.w700))),
              Expanded(flex: 3, child: Text('LABEL', style: GoogleFonts.inter(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.w700))),
              Expanded(flex: 2, child: Text('ADDED BY', style: GoogleFonts.inter(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.w700))),
              const SizedBox(width: 40),
            ],
          ),
          const SizedBox(height: 8),
          ...ip.whitelistedIps.asMap().entries.map((e) => _ipRow(e.value, e.key, ip)),
          const SizedBox(height: 8),
        ],
        // Add IP inline form
        if (_showAddIpRow) _buildAddIpForm(ip),
        TextButton.icon(
          onPressed: () => setState(() => _showAddIpRow = !_showAddIpRow),
          icon: Icon(_showAddIpRow ? Icons.close : Icons.add, size: 16),
          label: Text(
            _showAddIpRow ? 'Cancel' : '+ Add IP Address',
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          style: TextButton.styleFrom(foregroundColor: Colors.blueAccent),
        ),
      ],
    );
  }

  Widget _ipRow(String ipAddr, int index, IpWhitelistConfig ip) {
    final labels = ['Head Office VPN', 'Dev Team VPN', 'AWS Bastion', 'CI/CD Runner'];
    final label = index < labels.length ? labels[index] : 'Custom Range';
    final isCurrentIp = ipAddr == _currentIp;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isCurrentIp
            ? Colors.blueAccent.withValues(alpha: 0.06)
            : Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCurrentIp
              ? Colors.blueAccent.withValues(alpha: 0.25)
              : Colors.white.withValues(alpha: 0.07),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Text(
                  ipAddr,
                  style: GoogleFonts.robotoMono(color: Colors.white, fontSize: 13),
                ),
                if (isCurrentIp) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('YOU', style: GoogleFonts.inter(color: Colors.blueAccent, fontSize: 9, fontWeight: FontWeight.w800)),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(label, style: GoogleFonts.inter(color: Colors.white54, fontSize: 13)),
          ),
          Expanded(
            flex: 2,
            child: Text('Super Admin', style: GoogleFonts.inter(color: Colors.white38, fontSize: 12)),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                final newList = List<String>.from(ip.whitelistedIps)..removeAt(index);
                _settings = _settings!.copyWith(ipWhitelist: ip.copyWith(whitelistedIps: newList));
                _markDirty();
              });
            },
            icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
            tooltip: 'Remove',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildAddIpForm(IpWhitelistConfig ip) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextField(
              controller: _ipController,
              style: GoogleFonts.robotoMono(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: '192.168.1.0/24',
                hintStyle: GoogleFonts.robotoMono(color: Colors.white24, fontSize: 13),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.04),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                labelText: 'IP / CIDR',
                labelStyle: GoogleFonts.inter(color: Colors.white38, fontSize: 11),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 3,
            child: TextField(
              controller: _ipLabelController,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'e.g. Office VPN',
                hintStyle: GoogleFonts.inter(color: Colors.white24, fontSize: 13),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.04),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                labelText: 'Label',
                labelStyle: GoogleFonts.inter(color: Colors.white38, fontSize: 11),
              ),
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: () {
              final rawIp = _ipController.text.trim();
              if (rawIp.isEmpty) return;
              // Basic CIDR / IP validation
              final ipPattern = RegExp(r'^(\d{1,3}\.){3}\d{1,3}(\/\d{1,2})?$');
              if (!ipPattern.hasMatch(rawIp)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Invalid IP or CIDR format', style: GoogleFonts.inter()),
                    backgroundColor: Colors.redAccent,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
                return;
              }
              setState(() {
                final newList = [...ip.whitelistedIps, rawIp];
                _settings = _settings!.copyWith(ipWhitelist: ip.copyWith(whitelistedIps: newList));
                _ipController.clear();
                _ipLabelController.clear();
                _showAddIpRow = false;
                _markDirty();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Add', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showIpWarning() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Ensure $_currentIp is whitelisted before saving, or you will be locked out!',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange.shade900,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ─── Section E: Login Controls ────────────────────────────────────────────
  Widget _buildLoginControls() {
    final l = _settings!.loginControls;
    return _section(
      'Login Controls',
      'Brute-force protection, CAPTCHA and device notifications',
      Icons.lock_person_outlined,
      Colors.greenAccent,
      [
        _stepperRow(
          'Max Failed Login Attempts Before Lockout',
          'Account will be locked after this many consecutive failures',
          l.maxFailedAttempts,
          3, 10,
          (v) => setState(() {
            _settings = _settings!.copyWith(loginControls: l.copyWith(maxFailedAttempts: v));
            _markDirty();
          }),
        ),
        _dropdownRow(
          'Account Lockout Duration',
          'How long a locked account remains inaccessible',
          _lockoutLabel(l.lockoutDurationMinutes),
          ['15 min', '30 min', '1 hour', '24 hours', 'Permanent (manual unlock required)'],
          (v) => setState(() {
            _settings = _settings!.copyWith(loginControls: l.copyWith(lockoutDurationMinutes: _lockoutMinutes(v!)));
            _markDirty();
          }),
        ),
        _dropdownRow(
          'CAPTCHA on Login Page',
          'When to show CAPTCHA challenge to users',
          'After 3 Failed Attempts',
          ['Disabled', 'After 3 Failed Attempts', 'Always Show'],
          (v) => _markDirty(),
        ),
        _toggleRow(
          'Email Alert on Suspicious Login',
          'Notify account owner when login is from new device, country, or after failures',
          l.emailOnLockout,
          (v) => setState(() {
            _settings = _settings!.copyWith(loginControls: l.copyWith(emailOnLockout: v));
            _markDirty();
          }),
        ),
        _toggleRow(
          'Login from New Device Notification',
          'Send push/email when a new device is used to log in',
          true,
          (v) => _markDirty(),
        ),
      ],
    );
  }

  String _lockoutLabel(int mins) {
    if (mins == 15) return '15 min';
    if (mins == 30) return '30 min';
    if (mins == 60) return '1 hour';
    if (mins == 1440) return '24 hours';
    return 'Permanent (manual unlock required)';
  }

  int _lockoutMinutes(String label) {
    if (label == '15 min') return 15;
    if (label == '30 min') return 30;
    if (label == '1 hour') return 60;
    if (label == '24 hours') return 1440;
    return 99999;
  }

  // ─── Danger Zone ──────────────────────────────────────────────────────────
  Widget _buildDangerZone() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 20),
              const SizedBox(width: 12),
              Text(
                'Danger Zone',
                style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.redAccent),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'These actions are irreversible and will immediately affect all platform users.',
            style: GoogleFonts.inter(color: Colors.white38, fontSize: 13),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _showForceLogoutDialog,
                icon: const Icon(Icons.logout, size: 16),
                label: const Text('Force Log Out All Admins'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.key_off_outlined, size: 16),
                label: const Text('Revoke All API Tokens'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orangeAccent,
                  side: const BorderSide(color: Colors.orangeAccent),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  // ─── Reusable control widgets ─────────────────────────────────────────────
  Widget _toggleRow(String title, String subtitle, bool value, Function(bool) onChanged, {bool warningIfOff = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                const SizedBox(height: 3),
                Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: Colors.white38)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.blueAccent,
            inactiveThumbColor: Colors.white30,
            inactiveTrackColor: Colors.white12,
          ),
        ],
      ),
    );
  }

  Widget _sliderRow(String title, String subtitle, double value, double min, double max, Function(double) onChanged, {String? valueLabel}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                  Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: Colors.white38)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  valueLabel ?? '${value.round()}',
                  style: GoogleFonts.robotoMono(color: Colors.blueAccent, fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.blueAccent,
              inactiveTrackColor: Colors.white12,
              thumbColor: Colors.blueAccent,
              overlayColor: Colors.blueAccent.withValues(alpha: 0.15),
              valueIndicatorColor: Colors.blueAccent,
              trackHeight: 4,
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: (max - min).round(),
              onChanged: onChanged,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${min.round()} chars', style: GoogleFonts.inter(color: Colors.white24, fontSize: 10)),
              Text('${max.round()} chars', style: GoogleFonts.inter(color: Colors.white24, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stepperRow(String title, String subtitle, int value, int min, int max, Function(int) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                const SizedBox(height: 3),
                Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: Colors.white38)),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: value > min ? () => onChanged(value - 1) : null,
                  icon: const Icon(Icons.remove, size: 16, color: Colors.white54),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  constraints: const BoxConstraints(),
                ),
                Container(
                  width: 40,
                  alignment: Alignment.center,
                  child: Text(
                    '$value',
                    style: GoogleFonts.robotoMono(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  onPressed: value < max ? () => onChanged(value + 1) : null,
                  icon: const Icon(Icons.add, size: 16, color: Colors.white54),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dropdownRow(String title, String subtitle, String value, List<String> options, Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                const SizedBox(height: 3),
                Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: Colors.white38)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          DropdownButtonHideUnderline(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              constraints: const BoxConstraints(minWidth: 180),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: DropdownButton<String>(
                value: options.contains(value) ? value : options.first,
                dropdownColor: const Color(0xFF1E293B),
                style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                iconEnabledColor: Colors.white38,
                items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _checkboxRow(String label, bool value, ValueChanged<bool?> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(6),
        child: Row(
          children: [
            Checkbox(
              value: value,
              onChanged: onChanged,
              activeColor: Colors.blueAccent,
              side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
            Text(label, style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
