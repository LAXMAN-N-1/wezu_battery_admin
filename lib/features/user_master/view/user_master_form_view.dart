import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/widgets/admin_ui_components.dart';
import '../data/models/user.dart';
import '../data/models/role.dart';
import '../data/providers/user_master_providers.dart';

enum _UserReviewAction { edit, suspend, delete, reactivate }

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
  String? _selectedRoleId;
  String? _userId;
  _UserReviewAction _requestedAction = _UserReviewAction.edit;
  int? _selectedDealerId;
  final Set<int> _selectedStationIds = <int>{};
  final Set<int> _selectedWarehouseIds = <int>{};
  String _assignedStation = 'Global';
  UserStatus _status = UserStatus.active;
  bool _twoFactorEnabled = false;
  bool _autoGeneratePassword = false;
  bool _isLoadingInitialUser = false;
  bool _isSaving = false;
  bool _didLoadInitialData = false;

  final List<String> _stations = [
    'Global',
    'Station A',
    'Station B',
    'Hyderabad HUB',
  ];

  /// Convert snake_case DB role name to Display Name
  String _displayRoleName(String dbName) {
    return dbName
        .split('_')
        .map(
          (word) => word.isNotEmpty
              ? '${word[0].toUpperCase()}${word.substring(1)}'
              : '',
        )
        .join(' ');
  }

  Role? _selectedRole(List<Role> roles) {
    for (final role in roles) {
      if (role.id == _selectedRoleId) return role;
    }
    return null;
  }

  bool _isDealerScopedRole(Role? role) {
    if (role == null) return false;
    return role.requiresDealerId;
  }

  bool _isLogisticsScopedRole(Role? role) {
    if (role == null) return false;
    final userType = role.userType?.trim().toLowerCase();
    return role.requiresWarehouseIds || userType == 'logistics';
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

  bool get _isEditMode => _userId != null;
  bool get _canEditFields =>
      !_isEditMode || _requestedAction == _UserReviewAction.edit;

  _UserReviewAction _parseRequestedAction(String? rawAction) {
    switch (rawAction?.trim().toLowerCase()) {
      case 'suspend':
        return _UserReviewAction.suspend;
      case 'delete':
        return _UserReviewAction.delete;
      case 'reactivate':
        return _UserReviewAction.reactivate;
      case 'edit':
      default:
        return _UserReviewAction.edit;
    }
  }

  String _actionLabel(_UserReviewAction action) {
    switch (action) {
      case _UserReviewAction.edit:
        return 'Edit Details';
      case _UserReviewAction.suspend:
        return 'Suspend User';
      case _UserReviewAction.delete:
        return 'Delete User';
      case _UserReviewAction.reactivate:
        return 'Reactivate User';
    }
  }

  String _actionButtonLabel(_UserReviewAction action) {
    switch (action) {
      case _UserReviewAction.edit:
        return 'Save Changes';
      case _UserReviewAction.suspend:
        return 'Confirm Suspension';
      case _UserReviewAction.delete:
        return 'Confirm Delete';
      case _UserReviewAction.reactivate:
        return 'Confirm Reactivation';
    }
  }

  Color _actionColor(_UserReviewAction action) {
    switch (action) {
      case _UserReviewAction.edit:
        return const Color(0xFF3B82F6);
      case _UserReviewAction.suspend:
        return const Color(0xFFF59E0B);
      case _UserReviewAction.delete:
        return const Color(0xFFEF4444);
      case _UserReviewAction.reactivate:
        return const Color(0xFF22C55E);
    }
  }

  String _actionDescription(_UserReviewAction action) {
    switch (action) {
      case _UserReviewAction.edit:
        return 'Review the loaded profile data, adjust the fields you need, and save the update.';
      case _UserReviewAction.suspend:
        return 'Review the user details, provide the suspension reason, and confirm before blocking access.';
      case _UserReviewAction.delete:
        return 'Review the user details and confirm before deleting the linked account.';
      case _UserReviewAction.reactivate:
        return 'Review the user details and confirm before restoring access.';
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didLoadInitialData) return;
    _didLoadInitialData = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExistingUserIfNeeded();
    });
  }

  Future<void> _loadExistingUserIfNeeded() async {
    final queryParams = GoRouterState.of(context).uri.queryParameters;
    final userId = queryParams['id'];
    final requestedAction = _parseRequestedAction(queryParams['action']);
    if (userId == null || userId.isEmpty) return;

    setState(() {
      _userId = userId;
      _requestedAction = requestedAction;
      _isLoadingInitialUser = true;
    });

    try {
      final user = await ref
          .read(userMasterRepositoryProvider)
          .getUserById(userId);
      if (!mounted) return;
      setState(() {
        _nameController.text = user.fullName;
        _emailController.text = user.email;
        _phoneController.text = user.phone ?? '';
        _selectedRoleId = user.roleId;
        _selectedDealerId = user.dealerId;
        _selectedStationIds
          ..clear()
          ..addAll(user.stationIds);
        _selectedWarehouseIds
          ..clear()
          ..addAll(user.warehouseIds);
        _assignedStation = user.assignedStationName ?? 'Global';
        _status = user.status;
        _notesController.text = user.notes ?? '';
        _isLoadingInitialUser = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoadingInitialUser = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load user: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveUser() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedRoleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a role'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final roles = ref.read(rolesProvider).valueOrNull ?? const <Role>[];
    final selectedRole = _selectedRole(roles);
    if (selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selected role is no longer available.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_requestedAction == _UserReviewAction.edit &&
        _isDealerScopedRole(selectedRole) &&
        selectedRole.requiresDealerId &&
        _selectedDealerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select a dealer before saving this role.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_isEditMode &&
        _requestedAction == _UserReviewAction.suspend &&
        _notesController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a suspension reason before continuing.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirmed = await _confirmAction();
    if (confirmed != true) return;

    setState(() => _isSaving = true);

    try {
      final repo = ref.read(userMasterRepositoryProvider);
      final phoneNumber = _phoneController.text.trim();
      final sortedStationIds = _selectedStationIds.toList()..sort();
      final sortedWarehouseIds = _selectedWarehouseIds.toList()..sort();
      if (_isEditMode) {
        switch (_requestedAction) {
          case _UserReviewAction.edit:
            await repo.updateUser(_userId!, {
              'full_name': _nameController.text.trim(),
              'email': _emailController.text.trim(),
              'phone_number': phoneNumber.isEmpty ? null : phoneNumber,
              'role_id': int.tryParse(_selectedRoleId!),
              'dealer_id': _isDealerScopedRole(selectedRole)
                  ? _selectedDealerId
                  : null,
              'station_ids': _isDealerScopedRole(selectedRole)
                  ? sortedStationIds
                  : <int>[],
              'warehouse_ids': _isLogisticsScopedRole(selectedRole)
                  ? sortedWarehouseIds
                  : <int>[],
            });
            break;
          case _UserReviewAction.suspend:
            await repo.suspendUser(
              _userId!,
              reason: _notesController.text.trim(),
            );
            break;
          case _UserReviewAction.delete:
            await repo.deleteUser(_userId!);
            break;
          case _UserReviewAction.reactivate:
            await repo.reactivateUser(_userId!);
            break;
        }
      } else {
        final payload = {
          'full_name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone_number': phoneNumber.isEmpty ? null : phoneNumber,
          'role_id': int.tryParse(_selectedRoleId!),
          if (_isDealerScopedRole(selectedRole)) 'dealer_id': _selectedDealerId,
          if (_isDealerScopedRole(selectedRole))
            'station_ids': sortedStationIds,
          if (_isLogisticsScopedRole(selectedRole))
            'warehouse_ids': sortedWarehouseIds,
          'password': _autoGeneratePassword ? null : _passwordController.text,
          'status': _status.name,
        };
        await repo.createUser(payload);
      }

      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_successMessage()),
            backgroundColor: Colors.green,
          ),
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
          SnackBar(
            content: Text('Failed to save user: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<bool?> _confirmAction() {
    final title = _actionLabel(_requestedAction);
    final color = _actionColor(_requestedAction);
    final message = switch (_requestedAction) {
      _UserReviewAction.edit =>
        'Save the reviewed changes for ${_nameController.text.trim().isEmpty ? 'this user' : _nameController.text.trim()}?',
      _UserReviewAction.suspend =>
        'Suspend ${_nameController.text.trim().isEmpty ? 'this user' : _nameController.text.trim()} with the reason you entered?',
      _UserReviewAction.delete =>
        'Delete ${_nameController.text.trim().isEmpty ? 'this user' : _nameController.text.trim()}? This removes the linked Supabase auth user too.',
      _UserReviewAction.reactivate =>
        'Reactivate ${_nameController.text.trim().isEmpty ? 'this user' : _nameController.text.trim()} and restore sign-in access?',
    };

    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: Text(title, style: const TextStyle(color: Colors.white)),
          content: Text(message, style: const TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: color),
              child: Text(_actionButtonLabel(_requestedAction)),
            ),
          ],
        );
      },
    );
  }

  String _successMessage() {
    if (!_isEditMode) {
      return 'User ${_nameController.text} saved successfully.';
    }
    switch (_requestedAction) {
      case _UserReviewAction.edit:
        return 'User ${_nameController.text} updated successfully.';
      case _UserReviewAction.suspend:
        return 'User ${_nameController.text} suspended successfully.';
      case _UserReviewAction.delete:
        return 'User ${_nameController.text} deleted successfully.';
      case _UserReviewAction.reactivate:
        return 'User ${_nameController.text} reactivated successfully.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _isEditMode ? _actionLabel(_requestedAction) : 'Add User';
    final subtitle = _isEditMode
        ? _actionDescription(_requestedAction)
        : 'Create a new user profile and provision access.';

    if (_isLoadingInitialUser) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: title,
            subtitle: subtitle,
            actionButton: OutlinedButton.icon(
              onPressed: () => context.go('/user-master'),
              icon: const Icon(Icons.arrow_back, color: Colors.white70),
              label: const Text(
                'Back to Users',
                style: TextStyle(color: Colors.white70),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
    final dealersAsync = ref.watch(userCreationDealersProvider);
    final stationsAsync = ref.watch(
      userCreationStationsProvider(_selectedDealerId),
    );
    final warehousesAsync = ref.watch(userCreationWarehousesProvider);
    final selectedRole = _selectedRole(
      rolesAsync.valueOrNull ?? const <Role>[],
    );

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
            if (_isEditMode) ...[
              _buildActionReviewCard(),
              const SizedBox(height: 24),
            ],
            if (_canEditFields && selectedRole != null) ...[
              _buildAssignmentSection(
                selectedRole: selectedRole,
                dealersAsync: dealersAsync,
                stationsAsync: stationsAsync,
                warehousesAsync: warehousesAsync,
              ),
              const SizedBox(height: 24),
            ],
            Text(
              'Basic Information',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const Divider(color: Colors.white12, height: 32),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    'Full Name',
                    _nameController,
                    icon: Icons.person_outline,
                    required: true,
                    enabled: _canEditFields,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    'Email Address',
                    _emailController,
                    icon: Icons.email_outlined,
                    required: true,
                    enabled: _canEditFields,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    'Phone Number',
                    _phoneController,
                    icon: Icons.phone_outlined,
                    enabled: _canEditFields,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: !_canEditFields
                      ? _buildReadOnlyField(
                          'Role Assignment',
                          selectedRole == null
                              ? 'Unknown'
                              : _displayRoleName(selectedRole.name),
                        )
                      : rolesAsync.when(
                          loading: () => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Role Assignment',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                height: 48,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F172A),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white10),
                                ),
                                child: const Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          error: (err, _) => _buildDropdownField(
                            'Role Assignment',
                            ['admin', 'customer', 'dealer'],
                            'admin',
                            (_) {},
                          ),
                          data: (roles) {
                            final roleIds = roles.map((r) => r.id).toList();
                            if (_selectedRoleId == null && roleIds.isNotEmpty) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted && _selectedRoleId == null) {
                                  setState(
                                    () => _selectedRoleId = roleIds.first,
                                  );
                                }
                              });
                            }
                            return _buildDynamicRoleDropdown(
                              'Role Assignment',
                              roles,
                            );
                          },
                        ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _isEditMode
                      ? _buildReadOnlyField(
                          'Assigned Station / Region',
                          _assignedStation,
                        )
                      : _buildDropdownField(
                          'Assigned Station / Region',
                          _stations,
                          _assignedStation,
                          (val) => setState(() => _assignedStation = val!),
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _isEditMode
                      ? _buildReadOnlyField(
                          'Account Status',
                          _status.name.toUpperCase(),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Account Status',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F172A),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white10),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<UserStatus>(
                                  value: _status,
                                  isExpanded: true,
                                  dropdownColor: const Color(0xFF1E293B),
                                  style: const TextStyle(color: Colors.white),
                                  icon: const Icon(
                                    Icons.arrow_drop_down,
                                    color: Colors.white54,
                                  ),
                                  onChanged: (val) =>
                                      setState(() => _status = val!),
                                  items: UserStatus.values
                                      .map(
                                        (v) => DropdownMenuItem(
                                          value: v,
                                          child: Text(v.name.toUpperCase()),
                                        ),
                                      )
                                      .toList(),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
            if (!_isEditMode) ...[
              const SizedBox(height: 32),
              Text(
                'Security',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
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
                            const Text(
                              'Password',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Row(
                              children: [
                                const Text(
                                  'Auto-generate',
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                                ),
                                Switch(
                                  value: _autoGeneratePassword,
                                  onChanged: (val) => setState(() {
                                    _autoGeneratePassword = val;
                                    if (val) _passwordController.clear();
                                  }),
                                  activeTrackColor: Colors.blueAccent,
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        TextFormField(
                          controller: _passwordController,
                          enabled: !_autoGeneratePassword,
                          obscureText: true,
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDeco(
                            icon: Icons.lock_outline,
                            hint: _autoGeneratePassword
                                ? 'Password will be auto-generated and emailed'
                                : 'Enter manual password',
                          ),
                          validator: (val) =>
                              !_autoGeneratePassword &&
                                  (val == null || val.isEmpty)
                              ? 'Required'
                              : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(top: 24),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.blue.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Two-Factor Authentication',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Require 2FA for this user login',
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _twoFactorEnabled,
                            onChanged: (val) =>
                                setState(() => _twoFactorEnabled = val),
                            activeTrackColor: Colors.blueAccent,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 32),
            Text(
              'Notes / Context',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const Divider(color: Colors.white12, height: 32),
            TextFormField(
              controller: _notesController,
              maxLines: 4,
              enabled:
                  !_isEditMode ||
                  _requestedAction == _UserReviewAction.edit ||
                  _requestedAction == _UserReviewAction.suspend,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDeco(
                icon: Icons.note_alt_outlined,
                hint: _requestedAction == _UserReviewAction.suspend
                    ? 'Required: why are you suspending this user?'
                    : 'Any additional context about this user...',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionReviewCard() {
    final color = _actionColor(_requestedAction);
    final availableActions = [
      _UserReviewAction.edit,
      if (_status != UserStatus.suspended) _UserReviewAction.suspend,
      if (_status == UserStatus.suspended) _UserReviewAction.reactivate,
      _UserReviewAction.delete,
    ];

    if (!availableActions.contains(_requestedAction)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _requestedAction = availableActions.first;
          });
        }
      });
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.fact_check_outlined, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Requested Action Review',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'You were redirected here from the users table. Review the loaded user data, switch the action if needed, then confirm the final step.',
            style: const TextStyle(color: Colors.white70, height: 1.4),
          ),
          const SizedBox(height: 16),
          _buildActionSelector(availableActions),
        ],
      ),
    );
  }

  Widget _buildActionSelector(List<_UserReviewAction> availableActions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Action To Perform',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: availableActions.map((action) {
            final selected = _requestedAction == action;
            final color = _actionColor(action);
            return ChoiceChip(
              label: Text(
                _actionLabel(action),
                style: TextStyle(
                  color: selected ? Colors.white : Colors.white70,
                ),
              ),
              selected: selected,
              onSelected: (_) => setState(() => _requestedAction = action),
              backgroundColor: const Color(0xFF0F172A),
              selectedColor: color.withValues(alpha: 0.9),
              side: BorderSide(
                color: selected ? color : Colors.white.withValues(alpha: 0.08),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAssignmentSection({
    required Role selectedRole,
    required AsyncValue<List<Map<String, dynamic>>> dealersAsync,
    required AsyncValue<List<Map<String, dynamic>>> stationsAsync,
    required AsyncValue<List<Map<String, dynamic>>> warehousesAsync,
  }) {
    final showDealerScope = _isDealerScopedRole(selectedRole);
    final showWarehouseScope = _isLogisticsScopedRole(selectedRole);
    if (!showDealerScope && !showWarehouseScope) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Assignments',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Adjust pooled station or warehouse assignments for the selected role. Unselected items are released for reassignment.',
            style: TextStyle(color: Colors.white54, height: 1.4),
          ),
          if (showDealerScope) ...[
            const SizedBox(height: 18),
            dealersAsync.when(
              loading: () => const CircularProgressIndicator(),
              error: (error, _) => Text(
                'Unable to load dealers: $error',
                style: const TextStyle(color: Color(0xFFEF4444)),
              ),
              data: (dealers) => _buildDealerAssignmentSection(dealers),
            ),
            const SizedBox(height: 18),
            stationsAsync.when(
              loading: () => const CircularProgressIndicator(),
              error: (error, _) => Text(
                'Unable to load stations: $error',
                style: const TextStyle(color: Color(0xFFEF4444)),
              ),
              data: (stations) => _buildEntityChipPool(
                title: 'Station Pool',
                emptyText: _selectedDealerId == null
                    ? 'Select a dealer first.'
                    : 'No stations available for this dealer.',
                items: stations,
                selectedIds: _selectedStationIds,
                onToggle: (id) => setState(() {
                  if (_selectedStationIds.contains(id)) {
                    _selectedStationIds.remove(id);
                  } else {
                    _selectedStationIds.add(id);
                  }
                }),
              ),
            ),
          ],
          if (showWarehouseScope) ...[
            const SizedBox(height: 18),
            warehousesAsync.when(
              loading: () => const CircularProgressIndicator(),
              error: (error, _) => Text(
                'Unable to load warehouses: $error',
                style: const TextStyle(color: Color(0xFFEF4444)),
              ),
              data: (warehouses) => _buildEntityChipPool(
                title: 'Warehouse Pool',
                emptyText: 'No warehouses available right now.',
                items: warehouses,
                selectedIds: _selectedWarehouseIds,
                onToggle: (id) => setState(() {
                  if (_selectedWarehouseIds.contains(id)) {
                    _selectedWarehouseIds.remove(id);
                  } else {
                    _selectedWarehouseIds.add(id);
                  }
                }),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDealerAssignmentSection(List<Map<String, dynamic>> dealers) {
    final dealerItems = dealers
        .where((dealer) => dealer['id'] != null)
        .map(
          (dealer) => DropdownMenuItem<int>(
            value: (dealer['id'] as num).toInt(),
            child: Text(
              (dealer['business_name'] ?? dealer['name'] ?? 'Dealer')
                  .toString(),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dealer',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          initialValue: _selectedDealerId,
          isExpanded: true,
          decoration: _inputDeco(
            icon: Icons.storefront_outlined,
            hint: 'Select dealer',
          ),
          dropdownColor: const Color(0xFF1E293B),
          style: const TextStyle(color: Colors.white),
          items: dealerItems,
          onChanged: (value) => setState(() {
            _selectedDealerId = value;
            _selectedStationIds.clear();
          }),
        ),
      ],
    );
  }

  Widget _buildEntityChipPool({
    required String title,
    required String emptyText,
    required List<Map<String, dynamic>> items,
    required Set<int> selectedIds,
    required ValueChanged<int> onToggle,
  }) {
    final available = items.where((item) => item['id'] != null).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        if (available.isEmpty)
          Text(emptyText, style: const TextStyle(color: Colors.white38))
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: available.map((item) {
              final id = (item['id'] as num).toInt();
              final selected = selectedIds.contains(id);
              final label =
                  (item['name'] ??
                          item['business_name'] ??
                          item['code'] ??
                          '#$id')
                      .toString();
              return FilterChip(
                label: Text(
                  label,
                  style: TextStyle(
                    color: selected ? Colors.white : Colors.white70,
                  ),
                ),
                selected: selected,
                onSelected: (_) => onToggle(id),
                backgroundColor: const Color(0xFF1E293B),
                selectedColor: const Color(0xFF3B82F6).withValues(alpha: 0.85),
                side: BorderSide(
                  color: selected
                      ? const Color(0xFF3B82F6)
                      : Colors.white.withValues(alpha: 0.08),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  /// Builds the role dropdown from dynamically loaded roles
  Widget _buildDynamicRoleDropdown(String label, List<Role> roles) {
    final selectedRole = _selectedRole(roles);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
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
              value: selectedRole != null
                  ? selectedRole.id
                  : (roles.isNotEmpty ? roles.first.id : null),
              isExpanded: true,
              dropdownColor: const Color(0xFF1E293B),
              style: const TextStyle(color: Colors.white),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white54),
              onChanged: (val) => setState(() {
                _selectedRoleId = val;
                _selectedDealerId = null;
                _selectedStationIds.clear();
                _selectedWarehouseIds.clear();
              }),
              items: roles.map((role) {
                final displayName = _displayRoleName(role.name);
                final isSystem = role.isSystemRole;
                return DropdownMenuItem<String>(
                  value: role.id,
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSystem
                              ? Colors.purpleAccent
                              : Colors.blueAccent,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(displayName),
                      if (isSystem) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.purple.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'System',
                            style: TextStyle(
                              color: Colors.purpleAccent,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
    final roles = ref.watch(rolesProvider).valueOrNull ?? const <Role>[];
    final selectedRole = _selectedRole(roles);
    final selectedRoleName = selectedRole?.name;
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
                  _nameController.text.isNotEmpty
                      ? _nameController.text[0].toUpperCase()
                      : 'U',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _nameController.text.isNotEmpty
                    ? _nameController.text
                    : 'New User',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                selectedRoleName != null
                    ? _displayRoleName(selectedRoleName)
                    : 'Select a Role',
                style: TextStyle(
                  color: selectedRoleName != null
                      ? Colors.blueAccent
                      : Colors.white38,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _emailController.text.isNotEmpty
                    ? _emailController.text
                    : 'email@example.com',
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
              if (_isEditMode) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _actionColor(
                      _requestedAction,
                    ).withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: _actionColor(
                        _requestedAction,
                      ).withValues(alpha: 0.35),
                    ),
                  ),
                  child: Text(
                    _actionLabel(_requestedAction),
                    style: TextStyle(
                      color: _actionColor(_requestedAction),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveUser,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_rounded, color: Colors.white),
                  label: Text(
                    _isSaving
                        ? 'Processing...'
                        : _isEditMode
                        ? _actionButtonLabel(_requestedAction)
                        : 'Save User',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isEditMode
                        ? _actionColor(_requestedAction)
                        : const Color(0xFF3B82F6),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
              const Text(
                'Role Preview',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              if (selectedRoleName == null)
                const Text(
                  'Select a role to see its access level.',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                )
              else ...[
                _previewItem(Icons.dashboard_outlined, 'Dashboard', true),
                _previewItem(
                  Icons.people_outline,
                  'User Management',
                  selectedRoleName == 'admin',
                ),
                _previewItem(
                  Icons.inventory_2_outlined,
                  'Fleet & Inventory',
                  !['customer'].contains(selectedRoleName),
                ),
                _previewItem(
                  Icons.location_on_outlined,
                  'Stations',
                  !['customer'].contains(selectedRoleName),
                ),
                _previewItem(
                  Icons.attach_money,
                  'Finance',
                  ['admin', 'finance_manager'].contains(selectedRoleName),
                ),
                _previewItem(
                  Icons.settings_outlined,
                  'System Settings',
                  selectedRoleName == 'admin',
                ),
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
          Icon(
            icon,
            size: 16,
            color: hasAccess ? Colors.greenAccent : Colors.white24,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: hasAccess ? Colors.white70 : Colors.white24,
                fontSize: 12,
              ),
            ),
          ),
          Icon(
            hasAccess ? Icons.check_circle : Icons.cancel,
            size: 14,
            color: hasAccess ? Colors.greenAccent : Colors.white12,
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: Text(value, style: const TextStyle(color: Colors.white70)),
        ),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    IconData? icon,
    bool required = false,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label${required ? ' *' : ''}',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: enabled,
          style: const TextStyle(color: Colors.white),
          onChanged: (_) => setState(() {}), // Rebuild preview
          decoration: _inputDeco(icon: icon, hint: 'Enter $label'),
          validator: required
              ? (val) =>
                    val == null || val.isEmpty ? '$label is required' : null
              : null,
        ),
      ],
    );
  }

  Widget _buildDropdownField(
    String label,
    List<String> options,
    String value,
    ValueChanged<String?> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
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
              items: options
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
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
      prefixIcon: icon != null
          ? Icon(icon, color: Colors.white54, size: 20)
          : null,
      filled: true,
      fillColor: const Color(0xFF0F172A),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.blueAccent),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
