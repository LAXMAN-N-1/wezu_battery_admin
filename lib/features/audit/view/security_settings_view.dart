import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../data/providers/security_settings_provider.dart';

class SecuritySettingsView extends ConsumerStatefulWidget {
  const SecuritySettingsView({super.key});

  @override
  ConsumerState<SecuritySettingsView> createState() => _SecuritySettingsViewState();
}

class _SecuritySettingsViewState extends ConsumerState<SecuritySettingsView> {
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _ipLabelController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(securitySettingsProvider);

    // Listen for errors and show snackbar
    ref.listen(securitySettingsProvider.select((s) => s.error), (previous, next) {
      if (next != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next), backgroundColor: Colors.redAccent),
        );
      }
    });

    // Listen for save success (isSaving transitions from true to false with no error)
    ref.listen(securitySettingsProvider.select((s) => s.isSaving), (previous, isSaving) {
      if (previous == true && isSaving == false && state.error == null && !state.isDirty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Text('Security settings applied successfully'),
              ],
            ),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                if (state.error != null) ...[
                  const SizedBox(height: 16),
                  _buildWarningBanner(state.error!, Colors.redAccent),
                ],
                const SizedBox(height: 32),
                Expanded(
                  child: SingleChildScrollView(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final crossAxisCount = constraints.maxWidth > 1200 ? 2 : 1;
                        return Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: Column(
                                    children: [
                                      _buildPasswordPolicy(state),
                                      const SizedBox(height: 24),
                                      _buildSessionManagement(state),
                                      const SizedBox(height: 24),
                                      _buildLoginControls(state),
                                    ],
                                  ),
                                ),
                                if (crossAxisCount > 1) const SizedBox(width: 24),
                                if (crossAxisCount > 1)
                                  Expanded(
                                    flex: 1,
                                    child: Column(
                                      children: [
                                        _buildTwoFactorAuth(state),
                                        const SizedBox(height: 24),
                                        _buildIpWhitelist(state),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            if (crossAxisCount == 1) ...[
                               const SizedBox(height: 24),
                               _buildTwoFactorAuth(state),
                               const SizedBox(height: 24),
                               _buildIpWhitelist(state),
                            ],
                            const SizedBox(height: 100), // Space for bottom bar
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildBottomActionBuffer(state),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.security_rounded, color: Colors.blueAccent, size: 28),
                const SizedBox(width: 16),
                Text(
                  'Security Settings',
                  style: GoogleFonts.outfit(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Configure platform-wide security policies and access controls',
              style: GoogleFonts.inter(fontSize: 16, color: Colors.white54),
            ),
          ],
        ),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_user_rounded, color: Color(0xFF10B981), size: 16),
                  const SizedBox(width: 8),
                  Text('Security Score: 85', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(width: 4),
                  const Text('Good', style: TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(width: 16),
             Text(
              'Last Updated: Apr 7, 2026 10:30 AM',
              style: GoogleFonts.inter(color: Colors.white24, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCard({required String title, required IconData icon, required List<Widget> children, Color? accentColor}) {
    final color = accentColor ?? Colors.blueAccent;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildPasswordPolicy(SecuritySettingsState state) {
    return _buildCard(
      title: 'Password Policy',
      icon: Icons.lock_outline_rounded,
      children: [
        _sliderSetting('Minimum Length', 'min_password_length', 8, 20, state),
        _switchSetting('Require Uppercase Letter', 'At least one uppercase character (A-Z)', 'req_uppercase', state),
        _switchSetting('Require Number', 'At least one number (0-9)', 'req_number', state),
        _switchSetting('Require Special Character', 'e.g., !@#\$%^&*', 'req_special', state),
        _dropdownSetting('Password Expiry', 'password_expiry', ['Every 30 Days', 'Every 60 Days', 'Every 90 Days', 'Never'], state),
        _counterSetting('Prevent Reuse of Last N Passwords', 'reuse_limit', 0, 12, state),
      ],
    );
  }

  Widget _buildTwoFactorAuth(SecuritySettingsState state) {
    return _buildCard(
      title: 'Two-Factor Authentication (2FA)',
      icon: Icons.phonelink_lock_rounded,
      children: [
        _switchSetting('Enforce 2FA for Super Admins', 'Recommended', '2fa_super_admin', state),
        _switchSetting('Enforce 2FA for All Admins', '', '2fa_all_admin', state),
        _switchSetting('Enforce 2FA for Dealers', '', '2fa_dealers', state),
        const SizedBox(height: 16),
        Text('Allowed 2FA Methods', style: GoogleFonts.inter(fontSize: 13, color: Colors.white54, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        _checkboxItem('SMS OTP', '2fa_sms', state),
        _checkboxItem('Email OTP', '2fa_email', state),
        _checkboxItem('Authenticator App (TOTP)', '2fa_totp', state),
        const SizedBox(height: 24),
        _dropdownSetting('2FA Grace Period for New Users', '2fa_grace', ['3 Days', '7 Days', '14 Days'], state),
        const SizedBox(height: 24),
        _buildWarningBanner('Disabling 2FA for Super Admins is a security risk.', Colors.orange),
      ],
    );
  }

  Widget _buildSessionManagement(SecuritySettingsState state) {
    return _buildCard(
      title: 'Session Management',
      icon: Icons.timer_outlined,
      children: [
        _dropdownSetting('Admin Session Timeout (Inactivity)', 'session_timeout', ['15 minutes', '30 minutes', '60 minutes', '2 hours'], state),
        _counterSetting('Max Concurrent Sessions', 'max_sessions', 1, 10, state, suffix: '(Per Account)'),
        _dropdownSetting('Remember Me Duration', 'remember_me_days', ['7 Days', '14 Days', '30 Days'], state),
        const SizedBox(height: 32),
        _buildDangerButton('Force Logout All Admin Sessions', 'Immediately invalidate all active admin sessions.', () => _showForceLogoutDialog()),
      ],
    );
  }

  Widget _buildIpWhitelist(SecuritySettingsState state) {
    return _buildCard(
      title: 'IP Whitelist',
      icon: Icons.lan_outlined,
      children: [
        _switchSetting('Enable IP Whitelist', 'Restrict admin access to specific IP addresses', 'ip_whitelist_enabled', state),
        const SizedBox(height: 16),
        _buildWarningBanner('Enabling IP whitelist restricts admin access to listed IP only. Ensure your current IP is in the list before saving or you will be locked out.', Colors.orange),
        const SizedBox(height: 24),
        Row(
          children: [
            Text('Your Current IP: 192.168.1.100', style: GoogleFonts.inter(fontSize: 13, color: Colors.white38)),
            const Spacer(),
            TextButton.icon(onPressed: () {}, icon: const Icon(Icons.add, size: 14), label: const Text('Add My IP')),
          ],
        ),
        const SizedBox(height: 16),
        _buildIpTable(state),
        const SizedBox(height: 24),
        _buildIpEntryForm(),
      ],
    );
  }

  Widget _buildLoginControls(SecuritySettingsState state) {
    return _buildCard(
      title: 'Login Controls',
      icon: Icons.login_rounded,
      accentColor: Colors.orangeAccent,
      children: [
        _counterSetting('Max Failed Login Attempts Before Lockout', 'max_failed_attempts', 1, 10, state),
        _dropdownSetting('Account Lockout Duration', 'lockout_duration', ['15 minutes', '30 minutes', '60 minutes', '24 hours'], state),
        _dropdownSetting('CAPTCHA on Login Page', 'captcha_mode', ['Always', 'After 3 Failed Attempts', 'Never'], state),
        _switchSetting('Send Email Alert on Suspicious Login', 'New device, new country, or after failed attempts', 'alert_suspicious', state),
        _switchSetting('Login from New Device Notification', 'Sends push/email to account owner', 'alert_new_device', state),
      ],
    );
  }

  Widget _sliderSetting(String label, String key, double min, double max, SecuritySettingsState state) {
    final rawValue = (state.localSettings[key] ?? state.settings[key]);
    final value = (rawValue is num) ? rawValue.toDouble() : min;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label, style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
              const Spacer(),
              Text(value.toInt().toString(), style: GoogleFonts.robotoMono(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: (max - min).toInt(),
            activeColor: Colors.blueAccent,
            inactiveColor: Colors.white10,
            onChanged: (v) => ref.read(securitySettingsProvider.notifier).updateLocalSetting(key, v.toInt()),
          ),
        ],
      ),
    );
  }

  Widget _switchSetting(String label, String subtitle, String key, SecuritySettingsState state) {
    final value = state.localSettings[key] ?? state.settings[key] ?? false;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                if (subtitle.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(subtitle, style: GoogleFonts.inter(color: Colors.white24, fontSize: 11)),
                  ),
              ],
            ),
          ),
          Switch(
            value: value == true,
            onChanged: (v) => ref.read(securitySettingsProvider.notifier).updateLocalSetting(key, v),
            activeThumbColor: const Color(0xFF10B981),
            trackColor: WidgetStateProperty.resolveWith((states) {
               if (states.contains(WidgetState.selected)) return const Color(0xFF10B981).withValues(alpha: 0.3);
               return Colors.white10;
            }),
          ),
        ],
      ),
    );
  }

  Widget _dropdownSetting(String label, String key, List<String> options, SecuritySettingsState state) {
    final value = state.localSettings[key] ?? state.settings[key] ?? options.first;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Expanded(child: Text(label, style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white10),
            ),
            child: DropdownButton<String>(
              value: options.contains(value) ? value : options.first,
              dropdownColor: const Color(0xFF1E293B),
              underline: const SizedBox(),
              icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.white24),
              style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
              items: options.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => ref.read(securitySettingsProvider.notifier).updateLocalSetting(key, v),
            ),
          ),
        ],
      ),
    );
  }

  Widget _counterSetting(String label, String key, int min, int max, SecuritySettingsState state, {String suffix = ''}) {
    final value = (state.localSettings[key] ?? state.settings[key] ?? min) as int;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Flexible(child: Text(label, style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500))),
                if (suffix.isNotEmpty) ...[
                   const SizedBox(width: 8),
                   Text(suffix, style: GoogleFonts.inter(color: Colors.white24, fontSize: 11)),
                ],
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: value > min ? () => ref.read(securitySettingsProvider.notifier).updateLocalSetting(key, value - 1) : null,
                  icon: const Icon(Icons.remove, size: 14, color: Colors.white54),
                ),
                Text(value.toString(), style: GoogleFonts.robotoMono(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                IconButton(
                  onPressed: value < max ? () => ref.read(securitySettingsProvider.notifier).updateLocalSetting(key, value + 1) : null,
                  icon: const Icon(Icons.add, size: 14, color: Colors.white54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _checkboxItem(String label, String key, SecuritySettingsState state) {
    final value = state.localSettings[key] ?? state.settings[key] ?? false;
    return InkWell(
      onTap: () => ref.read(securitySettingsProvider.notifier).updateLocalSetting(key, !(value == true)),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: value == true ? Colors.blueAccent : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: value == true ? Colors.blueAccent : Colors.white24, width: 2),
              ),
              child: value == true ? const Icon(Icons.check, size: 12, color: Colors.white) : null,
            ),
            const SizedBox(width: 12),
            Text(label, style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildWarningBanner(String message, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: color, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(color: color.withValues(alpha: 0.9), fontSize: 12, fontWeight: FontWeight.w500, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIpTable(SecuritySettingsState state) {
    final rawList = state.localSettings['ip_whitelist'] ?? state.settings['ip_whitelist'] ?? [];
    final List<dynamic> ipList = rawList is List ? rawList : [];

    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(2),
        2: FlexColumnWidth(1.5),
        3: FlexColumnWidth(1.5),
        4: FixedColumnWidth(50),
      },
      children: [
        TableRow(
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white10))),
          children: [
            _tblHdr('IP Address / CIDR'),
            _tblHdr('Label'),
            _tblHdr('Added By'),
            _tblHdr('Added Date'),
            _tblHdr('Action'),
          ],
        ),
        ...ipList.asMap().entries.map((e) {
          final item = e.value is Map ? e.value : {'ip': e.value.toString(), 'label': 'Manual'};
          return TableRow(
            children: [
               _tblCell(item['ip'] ?? '-'),
               _tblCell(item['label'] ?? '-'),
               _tblCell(item['added_by'] ?? 'Sirisha'),
               _tblCell(item['date'] ?? 'Jan 10, 2026'),
               Center(
                 child: IconButton(
                   onPressed: () => ref.read(securitySettingsProvider.notifier).removeIpFromWhitelist(e.key),
                   icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                 ),
               ),
            ],
          );
        }),
      ],
    );
  }

  Widget _tblHdr(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(label, style: GoogleFonts.inter(color: Colors.white24, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _tblCell(String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(value, style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
    );
  }

  Widget _buildIpEntryForm() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: _buildInputField('IP Address / CIDR', 'e.g., 203.0.113.0/24', _ipController),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: _buildInputField('Label (Optional)', 'e.g., Office VPN', _ipLabelController),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: () {
            if (_ipController.text.isNotEmpty) {
              ref.read(securitySettingsProvider.notifier).addIpToWhitelist(_ipController.text, _ipLabelController.text);
              _ipController.clear();
              _ipLabelController.clear();
            }
          },
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Add'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  Widget _buildInputField(String label, String hint, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: Colors.white38, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white10),
            filled: true,
            fillColor: Colors.black26,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  Widget _buildDangerButton(String label, String sub, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
             Container(
               padding: const EdgeInsets.all(8),
               decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), shape: BoxShape.circle),
               child: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 18),
             ),
             const SizedBox(width: 16),
             Expanded(
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                    Text(label, style: GoogleFonts.inter(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                    Text(sub, style: GoogleFonts.inter(color: Colors.redAccent.withValues(alpha: 0.5), fontSize: 11)),
                 ],
               ),
             ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActionBuffer(SecuritySettingsState state) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          border: const Border(top: BorderSide(color: Colors.white10)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, -5)),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.blueAccent, size: 20),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    state.isDirty ? 'You have unsaved changes' : 'About Security Settings',
                    style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  Text(
                    state.isDirty ? 'Please review and save your security settings.' : 'These settings apply to the entire platform and affect all users immediately.',
                    style: GoogleFonts.inter(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 32),
            _actionButton('Discard Changes', Colors.white24, Colors.white, () => ref.read(securitySettingsProvider.notifier).discardChanges(), isOutlined: true),
            const SizedBox(width: 12),
            _actionButton(state.isSaving ? 'Applying...' : 'Save Security Settings', Colors.blueAccent, Colors.white, () {
               if (!state.isSaving) _showSaveConfirmDialog();
            }, icon: Icons.save_rounded),
          ],
        ),
      ),
    ).animate(target: state.isDirty ? 1 : 0).slideY(begin: 1.0, end: 0.0);
  }

  Widget _actionButton(String label, Color color, Color textColor, VoidCallback onTap, {bool isOutlined = false, IconData? icon}) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: icon != null ? Icon(icon, size: 16) : const SizedBox(),
      label: Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
      style: ElevatedButton.styleFrom(
        backgroundColor: isOutlined ? Colors.transparent : color,
        foregroundColor: textColor,
        elevation: isOutlined ? 0 : 4,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: isOutlined ? BorderSide(color: color) : BorderSide.none),
      ),
    );
  }

  void _showSaveConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Confirm Changes', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to apply these security settings? This will affect all users across the system.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(securitySettingsProvider.notifier).saveChanges();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            child: const Text('Apply Settings'),
          ),
        ],
      ),
    );
  }

  void _showForceLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController confirmController = TextEditingController();
        bool isInputValid = false;

        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
                const SizedBox(width: 16),
                Text('Critical Security Action', style: GoogleFonts.outfit(color: Colors.white)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'This will immediately invalidate ALL active administrative sessions across the entire platform.',
                  style: TextStyle(color: Colors.white70, height: 1.5),
                ),
                const SizedBox(height: 24),
                Text(
                  'Type "FORCE OUT" to confirm:',
                  style: GoogleFonts.inter(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmController,
                  onChanged: (v) => setDialogState(() => isInputValid = v == 'FORCE OUT'),
                  style: GoogleFonts.robotoMono(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'FORCE OUT',
                    hintStyle: const TextStyle(color: Colors.white10),
                    filled: true,
                    fillColor: Colors.black26,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: Colors.white38)),
              ),
              ElevatedButton(
                onPressed: isInputValid
                    ? () {
                        Navigator.pop(context);
                        ref.read(securitySettingsProvider.notifier).forceLogoutAll();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('All admin sessions terminated'), backgroundColor: Colors.redAccent),
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  disabledBackgroundColor: Colors.red.withValues(alpha: 0.1),
                ),
                child: const Text('Execute Force Logout'),
              ),
            ],
          ),
        );
      },
    );
  }
}
