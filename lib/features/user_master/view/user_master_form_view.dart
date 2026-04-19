import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/widgets/admin_ui_components.dart';
import '../data/models/user.dart';
import '../data/models/role.dart';
import '../data/providers/user_master_providers.dart';

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
  String? _selectedRoleName; // Will be populated from backend roles
  String _assignedStation = 'Global';
  UserStatus _status = UserStatus.active;
  bool _twoFactorEnabled = false;
  bool _autoGeneratePassword = false;
  bool _isSaving = false;

  final List<String> _stations = ['Global', 'Station A', 'Station B', 'Hyderabad HUB'];

  /// Convert snake_case DB role name to Display Name
  String _displayRoleName(String dbName) {
    return dbName
        .split('_')
        .map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : '')
        .join(' ');
  }

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

    if (_selectedRoleName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a role'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isSaving = true);
    
    try {
      final repo = ref.read(userMasterRepositoryProvider);
      
      final payload = {
        'full_name': _nameController.text,
        'email': _emailController.text,
        'phone_number': _phoneController.text,
        'role_name': _selectedRoleName, // Send exact DB role name
        'password': _autoGeneratePassword ? null : _passwordController.text,
        'status': _status.name,
      };

      await repo.createUser(payload);

      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User ${_nameController.text} saved successfully.'), backgroundColor: Colors.green),
        );
        
        // Invalidate the users list so it refreshes
        ref.invalidate(usersProvider);
        ref.invalidate(usersProviderByKey);
        ref.invalidate(userSummaryProvider);
        
        context.go('/user-master'); // Go back
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save user: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
    );
  }

  Widget _buildMainForm() {
    final rolesAsync = ref.watch(rolesProvider);

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
                // Dynamic role dropdown from backend
                Expanded(
                  child: rolesAsync.when(
                    loading: () => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Role Assignment', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                        ),
                      ],
                    ),
                    error: (err, _) => _buildDropdownField(
                      'Role Assignment',
                      ['admin', 'customer', 'dealer'],
                      _selectedRoleName ?? 'admin',
                      (val) => setState(() => _selectedRoleName = val),
                    ),
                    data: (roles) {
                      final roleNames = roles.map((r) => r.name).toList();
                      // Set default if not yet selected
                      if (_selectedRoleName == null && roleNames.isNotEmpty) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted && _selectedRoleName == null) {
                            setState(() => _selectedRoleName = roleNames.first);
                          }
                        });
                      }
                      return _buildDynamicRoleDropdown('Role Assignment', roles);
                    },
                  ),
                ),
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('Two-Factor Authentication', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              Text('Require 2FA for this user login', style: TextStyle(color: Colors.white54, fontSize: 12)),
                            ],
                          ),
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
            Text('Notes / Context', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const Divider(color: Colors.white12, height: 32),
            TextFormField(
              controller: _notesController,
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDeco(icon: Icons.note_alt_outlined, hint: 'Any additional context about this user...'),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the role dropdown from dynamically loaded roles
  Widget _buildDynamicRoleDropdown(String label, List<Role> roles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedRoleName != null && roles.any((r) => r.name == _selectedRoleName)
                  ? _selectedRoleName
                  : (roles.isNotEmpty ? roles.first.name : null),
              isExpanded: true,
              dropdownColor: const Color(0xFF1E293B),
              style: const TextStyle(color: Colors.white),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white54),
              onChanged: (val) => setState(() => _selectedRoleName = val),
              items: roles.map((role) {
                final displayName = _displayRoleName(role.name);
                final isSystem = role.isSystemRole;
                return DropdownMenuItem<String>(
                  value: role.name,
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSystem ? Colors.purpleAccent : Colors.blueAccent,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(displayName),
                      if (isSystem) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.purple.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('System', style: TextStyle(color: Colors.purpleAccent, fontSize: 9, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSidebarSettings() {
    return Column(
      children: [
        // Preview Card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Column(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.blueAccent.withValues(alpha: 0.15),
                child: Text(
                  _nameController.text.isNotEmpty ? _nameController.text[0].toUpperCase() : 'U',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _nameController.text.isNotEmpty ? _nameController.text : 'New User',
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 4),
              Text(
                _selectedRoleName != null ? _displayRoleName(_selectedRoleName!) : 'Select a Role',
                style: TextStyle(
                  color: _selectedRoleName != null ? Colors.blueAccent : Colors.white38,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Text(_emailController.text.isNotEmpty ? _emailController.text : 'email@example.com', style: const TextStyle(color: Colors.white38, fontSize: 12)),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveUser,
                  icon: _isSaving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save_rounded, color: Colors.white),
                  label: Text(_isSaving ? 'Saving...' : 'Save User', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Permissions Preview
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Role Preview', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 12),
              if (_selectedRoleName == null)
                const Text('Select a role to see its access level.', style: TextStyle(color: Colors.white38, fontSize: 12))
              else ...[
                _previewItem(Icons.dashboard_outlined, 'Dashboard', true),
                _previewItem(Icons.people_outline, 'User Management', _selectedRoleName == 'admin'),
                _previewItem(Icons.inventory_2_outlined, 'Fleet & Inventory', !['customer'].contains(_selectedRoleName)),
                _previewItem(Icons.location_on_outlined, 'Stations', !['customer'].contains(_selectedRoleName)),
                _previewItem(Icons.attach_money, 'Finance', ['admin', 'finance_manager'].contains(_selectedRoleName)),
                _previewItem(Icons.settings_outlined, 'System Settings', _selectedRoleName == 'admin'),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _previewItem(IconData icon, String label, bool hasAccess) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: hasAccess ? Colors.greenAccent : Colors.white24),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: TextStyle(color: hasAccess ? Colors.white70 : Colors.white24, fontSize: 12))),
          Icon(hasAccess ? Icons.check_circle : Icons.cancel, size: 14, color: hasAccess ? Colors.greenAccent : Colors.white12),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {IconData? icon, bool required = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label${required ? ' *' : ''}', style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          onChanged: (_) => setState(() {}), // Rebuild preview
          decoration: _inputDeco(icon: icon, hint: 'Enter $label'),
          validator: required ? (val) => val == null || val.isEmpty ? '$label is required' : null : null,
        ),
      ],
    );
  }

  Widget _buildDropdownField(String label, List<String> options, String value, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: const Color(0xFF1E293B),
              style: const TextStyle(color: Colors.white),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white54),
              onChanged: onChanged,
              items: options.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
