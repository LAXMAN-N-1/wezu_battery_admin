import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/widgets/admin_ui_components.dart';
import '../data/models/user.dart';

class UserMasterFormView extends ConsumerStatefulWidget {
  const UserMasterFormView({super.key});

  @override
  ConsumerState<UserMasterFormView> createState() => _UserMasterFormViewState();
}

class _UserMasterFormViewState extends ConsumerState<UserMasterFormView> {
  final _formKey = GlobalKey<FormState>();
  
  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  // State variables
  String _selectedRole = 'Admin';
  String _assignedStation = 'Global';
  UserStatus _status = UserStatus.active;
  bool _twoFactorEnabled = false;
  bool _autoGeneratePassword = false;
  bool _isSaving = false;

  final List<String> _roles = ['Super Admin', 'Admin', 'Fleet Manager', 'Finance Manager', 'Dealer', 'Support Agent', 'Read-Only Viewer'];
  final List<String> _stations = ['Global', 'Station A', 'Station B', 'Hyderabad HUB'];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 800));

    // _payload = {
    //   'full_name': _nameController.text,
    //   'email': _emailController.text,
    //   'phone': _phoneController.text,
    //   'role_name': _selectedRole,
    //   'assigned_station_name': _assignedStation == 'Global' ? null : _assignedStation,
    //   'status': _status.name,
    //   'two_factor_enabled': _twoFactorEnabled,
    //   'notes': _notesController.text,
    // };

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User ${_nameController.text} saved successfully.'), backgroundColor: Colors.green),
      );
      context.go('/user-master'); // Go back
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              title: 'Add / Edit User',
              subtitle: 'Create a new user profile or modify an existing one.',
              actionButton: OutlinedButton.icon(
                onPressed: () => context.go('/user-master'),
                icon: const Icon(Icons.arrow_back, color: Colors.white70),
                label: const Text('Back to Users', style: TextStyle(color: Colors.white70)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 7, child: _buildMainForm()),
                const SizedBox(width: 24),
                Expanded(flex: 3, child: _buildSidebarSettings()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Basic Information', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const Divider(color: Colors.white12, height: 32),
            Row(
              children: [
                Expanded(child: _buildTextField('Full Name', _nameController, icon: Icons.person_outline, required: true)),
                const SizedBox(width: 16),
                Expanded(child: _buildTextField('Email Address', _emailController, icon: Icons.email_outlined, required: true)),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _buildTextField('Phone Number', _phoneController, icon: Icons.phone_outlined)),
                const SizedBox(width: 16),
                Expanded(child: _buildDropdownField('Role Assignment', _roles, _selectedRole, (val) => setState(() => _selectedRole = val!))),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _buildDropdownField('Assigned Station / Region', _stations, _assignedStation, (val) => setState(() => _assignedStation = val!))),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Account Status', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<UserStatus>(
                            value: _status,
                            isExpanded: true,
                            dropdownColor: const Color(0xFF1E293B),
                            style: const TextStyle(color: Colors.white),
                            icon: const Icon(Icons.arrow_drop_down, color: Colors.white54),
                            onChanged: (val) => setState(() => _status = val!),
                            items: UserStatus.values.map((v) => DropdownMenuItem(value: v, child: Text(v.name.toUpperCase()))).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text('Security', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const Divider(color: Colors.white12, height: 32),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Password', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                          Row(
                            children: [
                              const Text('Auto-generate', style: TextStyle(color: Colors.white54, fontSize: 12)),
                              Switch(
                                value: _autoGeneratePassword,
                                onChanged: (val) => setState(() {
                                  _autoGeneratePassword = val;
                                  if (val) _passwordController.clear();
                                }),
                                activeTrackColor: Colors.blueAccent,
                              ),
                            ],
                          )
                        ],
                      ),
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: _passwordController,
                        enabled: !_autoGeneratePassword,
                        obscureText: true,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDeco(icon: Icons.lock_outline, hint: _autoGeneratePassword ? 'Password will be auto-generated and emailed' : 'Enter manual password'),
                        validator: (val) => !_autoGeneratePassword && (val == null || val.isEmpty) ? 'Required' : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(top: 24),
                    decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blue.withValues(alpha: 0.2))),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Two-Factor Authentication', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            Text('Require 2FA for this user login', style: TextStyle(color: Colors.white54, fontSize: 12)),
                          ],
                        ),
                        Switch(
                          value: _twoFactorEnabled,
                          onChanged: (val) => setState(() => _twoFactorEnabled = val),
                          activeTrackColor: Colors.blueAccent,
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text('Additional Notes', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const Divider(color: Colors.white12, height: 32),
            TextFormField(
              controller: _notesController,
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDeco(hint: 'Internal remarks...'),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => context.go('/user-master'),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _isSaving ? null : _saveUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Save User Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarSettings() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: const Color(0xFF0F172A),
                child: const Icon(Icons.person, size: 50, color: Colors.white38),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.upload, size: 16, color: Colors.white),
                label: const Text('Upload Photo', style: TextStyle(color: Colors.white)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 8),
              const Text('JPG or PNG, max 2MB', style: TextStyle(color: Colors.white38, fontSize: 11)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               Text('Quick Actions', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
               const Divider(color: Colors.white12, height: 24),
               ListTile(
                 contentPadding: EdgeInsets.zero,
                 leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.email_outlined, color: Colors.blue, size: 20)),
                 title: const Text('Send Welcome Email', style: TextStyle(color: Colors.white, fontSize: 13)),
                 trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                 onTap: () {},
               ),
               ListTile(
                 contentPadding: EdgeInsets.zero,
                 leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.password, color: Colors.orange, size: 20)),
                 title: const Text('Force Password Reset', style: TextStyle(color: Colors.white, fontSize: 13)),
                 trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                 onTap: () {},
               ),
               ListTile(
                 contentPadding: EdgeInsets.zero,
                 leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.block, color: Colors.red, size: 20)),
                 title: const Text('Suspend User immediately', style: TextStyle(color: Colors.redAccent, fontSize: 13)),
                 trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                 onTap: () {},
               ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {IconData? icon, bool required = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
            if (required) const Text(' *', style: TextStyle(color: Colors.redAccent)),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: _inputDeco(icon: icon),
          validator: (val) => required && (val == null || val.isEmpty) ? 'Required' : null,
        ),
      ],
    );
  }

  Widget _buildDropdownField(String label, List<String> options, String currentValue, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: currentValue,
              isExpanded: true,
              dropdownColor: const Color(0xFF1E293B),
              style: const TextStyle(color: Colors.white),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white54),
              onChanged: onChanged,
              items: options.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDeco({IconData? icon, String? hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white38),
      prefixIcon: icon != null ? Icon(icon, color: Colors.white54, size: 20) : null,
      filled: true,
      fillColor: const Color(0xFF0F172A),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.blueAccent)),
    );
  }
}
