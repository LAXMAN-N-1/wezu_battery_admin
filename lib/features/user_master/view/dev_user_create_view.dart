import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/widgets/admin_ui_components.dart';
import '../data/models/role.dart';
import '../data/providers/user_master_providers.dart';

class DevUserCreateView extends ConsumerStatefulWidget {
  const DevUserCreateView({super.key});

  @override
  ConsumerState<DevUserCreateView> createState() => _DevUserCreateViewState();
}

class _DevUserCreateViewState extends ConsumerState<DevUserCreateView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  String? _selectedRoleId;
  bool _isSaving = false;
  bool _obscurePassword = true;
  Map<String, dynamic>? _createdUser;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  String _displayNameFromEmail(String email) {
    final localPart = email.split('@').first.trim();
    if (localPart.isEmpty) return 'Development User';
    return localPart
        .replaceAll(RegExp(r'[._-]+'), ' ')
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  String _canonicalRoleName(String? roleName) {
    final cleaned = roleName?.trim().toLowerCase() ?? '';
    return switch (cleaned) {
      'admin' => 'operations_admin',
      'dealer' => 'dealer_owner',
      'logistics' => 'logistics_manager',
      'superadmin' => 'super_admin',
      _ => cleaned,
    };
  }

  String _displayRoleName(String roleName) {
    final normalized = _canonicalRoleName(roleName);
    if (normalized.isEmpty) return 'Select a role';
    return normalized
        .split('_')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  String _userTypeForRole(String roleName) {
    final role = _canonicalRoleName(roleName);
    if (role == 'dealer_owner') return 'dealer';
    if (role.startsWith('dealer_')) return 'dealer_staff';
    if (role == 'support_agent') return 'support_agent';
    if ({
      'logistics_manager',
      'dispatcher',
      'fleet_manager',
      'warehouse_manager',
      'driver',
    }.contains(role)) {
      return 'logistics';
    }
    if ({
      'super_admin',
      'operations_admin',
      'security_admin',
      'finance_admin',
      'support_manager',
    }.contains(role)) {
      return 'admin';
    }
    return 'customer';
  }

  bool _requiresDealerProfile(String roleName) {
    return _canonicalRoleName(roleName) == 'dealer_owner';
  }

  Color _roleColor(String? roleName) {
    final role = _canonicalRoleName(roleName);
    if (role.startsWith('dealer_')) return const Color(0xFFF59E0B);
    if ({
      'logistics_manager',
      'dispatcher',
      'fleet_manager',
      'warehouse_manager',
      'driver',
    }.contains(role)) {
      return const Color(0xFF22D3EE);
    }
    if (role == 'support_agent' || role == 'support_manager') {
      return const Color(0xFFA78BFA);
    }
    if (role.isEmpty) return const Color(0xFF64748B);
    return const Color(0xFF60A5FA);
  }

  IconData _roleIcon(String? roleName) {
    final role = _canonicalRoleName(roleName);
    if (role.startsWith('dealer_')) return Icons.storefront_outlined;
    if ({
      'logistics_manager',
      'dispatcher',
      'fleet_manager',
      'warehouse_manager',
      'driver',
    }.contains(role)) {
      return Icons.local_shipping_outlined;
    }
    if (role == 'support_agent' || role == 'support_manager') {
      return Icons.support_agent_outlined;
    }
    return Icons.admin_panel_settings_outlined;
  }

  Map<String, dynamic> _payloadForRole({
    required String email,
    required String password,
    required String fullName,
    required Role role,
  }) {
    final roleId = int.tryParse(role.id);
    if (roleId == null) {
      throw StateError('Selected role is missing a numeric role id.');
    }

    final canonicalRoleName = _canonicalRoleName(role.name);
    final userType = role.userType?.trim().isNotEmpty == true
        ? role.userType!.trim()
        : _userTypeForRole(canonicalRoleName);
    final payload = <String, dynamic>{
      'email': email,
      'password': password,
      'full_name': fullName,
      'status': 'active',
      'role_id': roleId,
      'user_type': userType,
    };

    if (role.requiresDealerProfile ||
        _requiresDealerProfile(canonicalRoleName)) {
      payload['dealer_profile'] = {
        'business_name': '$fullName Dealer',
        'contact_person': fullName,
        'contact_email': email,
      };
    }

    return payload;
  }

  Future<void> _createUser() async {
    if (!_formKey.currentState!.validate()) return;
    final selectedRoleId = _selectedRoleId;
    final roles = ref.read(userCreationRolesProvider).valueOrNull ?? const [];
    final selectedRole = roles
        .where((role) => role.id == selectedRoleId)
        .firstOrNull;
    if (selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a role'),
          backgroundColor: Color(0xFFF59E0B),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
      _createdUser = null;
    });

    final email = _emailController.text.trim();
    final fullName = _nameController.text.trim().isEmpty
        ? _displayNameFromEmail(email)
        : _nameController.text.trim();

    try {
      final payload = _payloadForRole(
        email: email,
        password: _passwordController.text,
        fullName: fullName,
        role: selectedRole,
      );
      final created = await ref
          .read(userMasterRepositoryProvider)
          .createSupabaseUser(payload);

      ref.invalidate(usersProvider);
      ref.invalidate(usersProviderByKey);
      ref.invalidate(userSummaryProvider);

      if (!mounted) return;
      setState(() {
        _createdUser = created;
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Created ${created['email'] ?? email}'),
          backgroundColor: const Color(0xFF16A34A),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create user: $error'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'Create User',
            subtitle: 'Supabase account provisioning for development access.',
            actionButton: OutlinedButton.icon(
              onPressed: () => context.go('/user-master'),
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white70),
              label: const Text(
                'Users',
                style: TextStyle(color: Colors.white70),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 980;
              final form = _buildCreateForm();
              final preview = _buildPreviewPanel();
              if (!isWide) {
                return Column(
                  children: [form, const SizedBox(height: 20), preview],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 7, child: form),
                  const SizedBox(width: 24),
                  Expanded(flex: 4, child: preview),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCreateForm() {
    final rolesAsync = ref.watch(userCreationRolesProvider);

    return AdvancedCard(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.person_add_alt_1_rounded,
                    color: Color(0xFF60A5FA),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Account Details',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildTextField(
              controller: _emailController,
              label: 'Email',
              icon: Icons.mail_outline_rounded,
              hintText: 'name@example.com',
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                final email = value?.trim() ?? '';
                if (email.isEmpty) return 'Email is required';
                if (!email.contains('@') || !email.contains('.')) {
                  return 'Enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 18),
            _buildTextField(
              controller: _passwordController,
              label: 'Password',
              icon: Icons.lock_outline_rounded,
              obscureText: _obscurePassword,
              suffixIcon: IconButton(
                tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: Colors.white54,
                ),
              ),
              validator: (value) {
                final password = value ?? '';
                if (password.isEmpty) return 'Password is required';
                if (password.length < 8) return 'Minimum 8 characters';
                return null;
              },
            ),
            const SizedBox(height: 18),
            _buildTextField(
              controller: _nameController,
              label: 'Name',
              icon: Icons.badge_outlined,
              hintText: _displayNameFromEmail(_emailController.text),
            ),
            const SizedBox(height: 28),
            Text(
              'Role',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            _buildRoleSelector(rolesAsync),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _createUser,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.add_rounded, color: Colors.white),
                label: Text(
                  _isSaving ? 'Creating...' : 'Create User',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  disabledBackgroundColor: const Color(0xFF1E3A8A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleSelector(AsyncValue<List<Role>> rolesAsync) {
    return rolesAsync.when(
      loading: () => _buildRoleMenuShell(
        icon: Icons.hourglass_empty_rounded,
        label: 'Loading roles...',
        trailing: const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (error, _) => _buildRoleMenuShell(
        icon: Icons.error_outline_rounded,
        label: 'Unable to load roles',
        subtitle: error.toString(),
        trailing: IconButton(
          tooltip: 'Retry',
          onPressed: () => ref.invalidate(userCreationRolesProvider),
          icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
        ),
      ),
      data: (roles) {
        if (roles.isEmpty) {
          return _buildRoleMenuShell(
            icon: Icons.block_rounded,
            label: 'No roles available',
            subtitle: 'Create roles first, then return to this screen.',
          );
        }

        final selectedRole = roles
            .where((role) => role.id == _selectedRoleId)
            .firstOrNull;
        final selectedName = selectedRole?.name;

        return PopupMenuButton<String>(
          enabled: !_isSaving,
          color: const Color(0xFF1E293B),
          offset: const Offset(0, 58),
          constraints: const BoxConstraints(minWidth: 280, maxWidth: 420),
          onSelected: (roleId) {
            setState(() {
              _selectedRoleId = roleId;
              _createdUser = null;
            });
          },
          itemBuilder: (context) {
            final sortedRoles = [...roles]
              ..sort((a, b) => a.name.compareTo(b.name));
            return sortedRoles.map((role) {
              final roleName = _canonicalRoleName(role.name);
              final color = _roleColor(roleName);
              return PopupMenuItem<String>(
                value: role.id,
                child: Row(
                  children: [
                    Icon(_roleIcon(roleName), color: color, size: 18),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _displayRoleName(roleName),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (role.description.trim().isNotEmpty)
                            Text(
                              role.description,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 11,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList();
          },
          child: _buildRoleMenuShell(
            icon: _roleIcon(selectedName),
            label: selectedName == null
                ? 'Select from available roles'
                : _displayRoleName(selectedName),
            subtitle: selectedName == null
                ? null
                : _canonicalRoleName(selectedName),
            color: _roleColor(selectedName),
            trailing: const Icon(
              Icons.expand_more_rounded,
              color: Colors.white54,
            ),
          ),
        );
      },
    );
  }

  Widget _buildRoleMenuShell({
    required IconData icon,
    required String label,
    String? subtitle,
    Color? color,
    Widget? trailing,
  }) {
    final resolvedColor = color ?? const Color(0xFF64748B);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: resolvedColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: resolvedColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (subtitle != null && subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 12), trailing],
        ],
      ),
    );
  }

  Widget _buildPreviewPanel() {
    final email = _emailController.text.trim();
    final name = _nameController.text.trim().isEmpty
        ? _displayNameFromEmail(email)
        : _nameController.text.trim();
    final roles = ref.watch(userCreationRolesProvider).valueOrNull ?? const [];
    final selectedRole = roles
        .where((role) => role.id == _selectedRoleId)
        .firstOrNull;
    final selectedRoleName = selectedRole?.name;
    final roleColor = _roleColor(selectedRoleName);
    final roleIcon = _roleIcon(selectedRoleName);
    final canonicalRole = _canonicalRoleName(selectedRoleName);
    final userType = selectedRole == null
        ? 'Select a role'
        : selectedRole.userType ?? _userTypeForRole(selectedRole.name);

    return Column(
      children: [
        AdvancedCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: roleColor.withValues(alpha: 0.16),
                    child: Icon(roleIcon, color: roleColor),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          email.isEmpty ? 'email@example.com' : email,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildPreviewRow(
                'Role',
                selectedRoleName == null
                    ? 'Select a role'
                    : _displayRoleName(selectedRoleName),
              ),
              _buildPreviewRow(
                'Slug',
                canonicalRole.isEmpty ? '-' : canonicalRole,
              ),
              _buildPreviewRow('Role ID', selectedRole?.id ?? '-'),
              _buildPreviewRow('Type', userType),
              _buildPreviewRow('Status', 'active'),
              if (selectedRole != null &&
                  (selectedRole.requiresDealerProfile ||
                      _requiresDealerProfile(selectedRole.name)))
                _buildPreviewRow('Dealer', '$name Dealer'),
              if (selectedRole?.requiresDealerId == true) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.22),
                    ),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: Color(0xFFF59E0B),
                        size: 18,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Dealer staff roles may require a dealer assignment in the backend.',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        if (_createdUser != null) ...[
          const SizedBox(height: 20),
          AdvancedCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF22C55E),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Created',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildPreviewRow('User ID', '${_createdUser!['id'] ?? '-'}'),
                _buildPreviewRow(
                  'Supabase',
                  '${_createdUser!['supabase_subject'] ?? '-'}',
                ),
                _buildPreviewRow(
                  'Role',
                  '${_createdUser!['role_name'] ?? canonicalRole}',
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPreviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          SizedBox(
            width: 86,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hintText,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white),
          onChanged: (_) => setState(() {}),
          validator: validator,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: Colors.white30),
            prefixIcon: Icon(icon, color: Colors.white54, size: 20),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: const Color(0xFF0F172A),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 15,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF3B82F6)),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFEF4444)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFEF4444)),
            ),
          ),
        ),
      ],
    );
  }
}
