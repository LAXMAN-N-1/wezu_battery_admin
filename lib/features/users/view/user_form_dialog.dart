import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/user_model.dart';

class UserFormDialog extends StatefulWidget {
  final UserModel? user; // If provided, we are editing

  const UserFormDialog({super.key, this.user});

  @override
  State<UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  
  // Defaults
  KycStatus _kycStatus = KycStatus.pending;
  AccountStatus _accountStatus = AccountStatus.active;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user?.name ?? '');
    _emailController = TextEditingController(text: widget.user?.email ?? '');
    _phoneController = TextEditingController(text: widget.user?.phone ?? '');
    
    if (widget.user != null) {
      _kycStatus = widget.user!.kycStatus;
      _accountStatus = widget.user!.accountStatus;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.user != null;

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEditing ? 'Edit User' : 'Add New User',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              
              _buildTextField(
                controller: _nameController,
                label: 'Full Name',
                validator: (v) => v?.isEmpty ?? true ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _emailController,
                label: 'Email Address',
                validator: (v) => v?.isEmpty ?? true ? 'Email is required' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _phoneController,
                label: 'Phone Number',
                validator: (v) => v?.isEmpty ?? true ? 'Phone is required' : null,
              ),
              
              const SizedBox(height: 24),
              
              // Status Dropdowns (only visible for admins/editing usually, but good for "Add" too)
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<KycStatus>(
                      value: _kycStatus,
                      isExpanded: true,
                      dropdownColor: AppColors.surface,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: _inputDecoration('KYC Status'),
                      items: KycStatus.values.map((s) => DropdownMenuItem(
                        value: s,
                        child: Text(s.label, overflow: TextOverflow.ellipsis),
                      )).toList(),
                      onChanged: (v) => setState(() => _kycStatus = v!),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<AccountStatus>(
                      value: _accountStatus,
                      isExpanded: true,
                      dropdownColor: AppColors.surface,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: _inputDecoration('Account Status'),
                      items: AccountStatus.values.map((s) => DropdownMenuItem(
                        value: s,
                        child: Text(s.label, overflow: TextOverflow.ellipsis),
                      )).toList(),
                      onChanged: (v) => setState(() => _accountStatus = v!),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(isEditing ? 'Save Changes' : 'Create User'),
                  ),
                ],
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.textSecondary),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.border),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
        borderSide: BorderSide(color: AppColors.primary),
      ),
      filled: true,
      fillColor: AppColors.background.withValues(alpha: 0.5),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: _inputDecoration(label),
    );
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final user = UserModel(
        id: widget.user?.id ?? '', // ID handled by repo/backend
        name: _nameController.text,
        email: _emailController.text,
        phone: _phoneController.text,
        registrationDate: widget.user?.registrationDate ?? DateTime.now(),
        kycStatus: _kycStatus,
        accountStatus: _accountStatus,
        lastActive: DateTime.now(),
        walletBalance: widget.user?.walletBalance ?? 0,
        totalSwaps: widget.user?.totalSwaps ?? 0,
        vehicles: widget.user?.vehicles ?? [], // Empty for new users
        profilePhotoUrl: widget.user?.profilePhotoUrl,
      );
      
      Navigator.pop(context, user);
    }
  }
}
