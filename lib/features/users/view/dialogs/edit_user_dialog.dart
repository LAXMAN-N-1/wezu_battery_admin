import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/role.dart';
import '../../data/models/user.dart';
import '../../data/repositories/role_repository.dart';
import '../../provider/user_provider.dart';

class EditUserDialog extends ConsumerStatefulWidget {
  final User user;
  final Function(User updatedUser) onSubmit;

  const EditUserDialog({super.key, required this.user, required this.onSubmit});

  @override
  ConsumerState<EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends ConsumerState<EditUserDialog> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _roleReasonController;
  late String _selectedRole;
  List<Role> _availableRoles = [];
  bool _isLoadingRoles = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.fullName);
    _emailController = TextEditingController(text: widget.user.email);
    _phoneController = TextEditingController(text: widget.user.phoneNumber);
    _roleReasonController = TextEditingController();
    _selectedRole = widget.user.role;
    _loadRoles();
  }

  Future<void> _loadRoles() async {
    try {
      final roles = await RoleRepository().getRoles();
      if (mounted) {
        setState(() {
          _availableRoles = roles;
          _isLoadingRoles = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingRoles = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _roleReasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool hasRoleChanged = _selectedRole != widget.user.role;

    return Dialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(32),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.edit,
                      color: Colors.amber,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    'Edit User Profile',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white38,
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              _buildField('Full Name', _nameController, Icons.person_outline),
              const SizedBox(height: 16),
              _buildField('Email', _emailController, Icons.email_outlined),
              const SizedBox(height: 16),
              _buildField('Phone', _phoneController, Icons.phone_outlined),
              const SizedBox(height: 16),

              Text(
                'Role',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: _isLoadingRoles
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value:
                              _availableRoles.any(
                                (r) =>
                                    r.name.toLowerCase() ==
                                    _selectedRole.toLowerCase(),
                              )
                              ? _selectedRole
                              : null,
                          isExpanded: true,
                          dropdownColor: const Color(0xFF1E293B),
                          style: TextStyle(color: Colors.white, fontSize: 14),
                          hint: Text(
                            _selectedRole,
                            style: const TextStyle(color: Colors.white70),
                          ),
                          items: _availableRoles
                              .map(
                                (r) => DropdownMenuItem(
                                  value: r.name,
                                  child: Text(
                                    r.name[0].toUpperCase() +
                                        r.name.substring(1),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setState(() => _selectedRole = v!),
                        ),
                      ),
              ),

              if (hasRoleChanged) ...[
                const SizedBox(height: 16),
                _buildField(
                  'Reason for Role Change',
                  _roleReasonController,
                  Icons.info_outline,
                ),
              ],

              const SizedBox(height: 28),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Save Changes',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.white38, size: 18),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.amber),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  void _submit() async {
    bool hasRoleChanged = _selectedRole != widget.user.role;
    if (hasRoleChanged && _roleReasonController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide a reason for role change'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      if (hasRoleChanged) {
        final role = _availableRoles.firstWhere(
          (r) => r.name.toLowerCase() == _selectedRole.toLowerCase(),
        );
        await ref
            .read(userListProvider.notifier)
            .changeUserRole(
              widget.user.id,
              roleId: role.id,
              reason: _roleReasonController.text,
            );
      }

      final updated = widget.user.copyWith(
        fullName: _nameController.text,
        email: _emailController.text,
        phoneNumber: _phoneController.text,
        role: _selectedRole,
      );

      await ref.read(userListProvider.notifier).updateUser(updated);
      widget.onSubmit(updated);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}
