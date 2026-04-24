import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/widgets/admin_ui_components.dart';
import '../data/models/role.dart';
import '../data/providers/user_master_providers.dart';

class _StationDraft {
  _StationDraft(int index)
    : nameController = TextEditingController(text: 'Station ${index + 1}'),
      addressController = TextEditingController(),
      cityController = TextEditingController(text: 'Hyderabad'),
      latitudeController = TextEditingController(),
      longitudeController = TextEditingController(),
      totalSlotsController = TextEditingController(text: '8'),
      contactPhoneController = TextEditingController();

  final TextEditingController nameController;
  final TextEditingController addressController;
  final TextEditingController cityController;
  final TextEditingController latitudeController;
  final TextEditingController longitudeController;
  final TextEditingController totalSlotsController;
  final TextEditingController contactPhoneController;

  String stationType = 'automated';
  bool is24x7 = false;

  Map<String, dynamic> toPayload() {
    return {
      'name': nameController.text.trim(),
      'address': addressController.text.trim(),
      'city': cityController.text.trim(),
      'latitude': double.parse(latitudeController.text.trim()),
      'longitude': double.parse(longitudeController.text.trim()),
      'station_type': stationType,
      'total_slots': int.parse(totalSlotsController.text.trim()),
      'contact_phone': contactPhoneController.text.trim().isEmpty
          ? null
          : contactPhoneController.text.trim(),
      'is_24x7': is24x7,
    };
  }

  void dispose() {
    nameController.dispose();
    addressController.dispose();
    cityController.dispose();
    latitudeController.dispose();
    longitudeController.dispose();
    totalSlotsController.dispose();
    contactPhoneController.dispose();
  }
}

class _WarehouseDraft {
  _WarehouseDraft(int index)
    : nameController = TextEditingController(text: 'Warehouse ${index + 1}'),
      codeController = TextEditingController(text: 'WH-${index + 1}'),
      addressController = TextEditingController(),
      cityController = TextEditingController(text: 'Hyderabad'),
      stateController = TextEditingController(text: 'Telangana'),
      pincodeController = TextEditingController();

  final TextEditingController nameController;
  final TextEditingController codeController;
  final TextEditingController addressController;
  final TextEditingController cityController;
  final TextEditingController stateController;
  final TextEditingController pincodeController;

  Map<String, dynamic> toPayload() {
    return {
      'name': nameController.text.trim(),
      'code': codeController.text.trim().toUpperCase(),
      'address': addressController.text.trim(),
      'city': cityController.text.trim(),
      'state': stateController.text.trim(),
      'pincode': pincodeController.text.trim(),
    };
  }

  void dispose() {
    nameController.dispose();
    codeController.dispose();
    addressController.dispose();
    cityController.dispose();
    stateController.dispose();
    pincodeController.dispose();
  }
}

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
  final _phoneController = TextEditingController();

  final _businessNameController = TextEditingController();
  final _dealerContactPersonController = TextEditingController();
  final _dealerContactPhoneController = TextEditingController();
  final _dealerAddressController = TextEditingController();
  final _dealerCityController = TextEditingController(text: 'Hyderabad');
  final _dealerStateController = TextEditingController(text: 'Telangana');
  final _dealerPincodeController = TextEditingController();

  String? _selectedRoleId;
  int? _selectedDealerId;
  final Set<int> _selectedStationIds = <int>{};
  final Set<int> _selectedWarehouseIds = <int>{};
  final List<_StationDraft> _stationDrafts = <_StationDraft>[];
  final List<_WarehouseDraft> _warehouseDrafts = <_WarehouseDraft>[];

  bool _isSaving = false;
  bool _obscurePassword = true;
  Map<String, dynamic>? _createdUser;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _businessNameController.dispose();
    _dealerContactPersonController.dispose();
    _dealerContactPhoneController.dispose();
    _dealerAddressController.dispose();
    _dealerCityController.dispose();
    _dealerStateController.dispose();
    _dealerPincodeController.dispose();
    for (final station in _stationDrafts) {
      station.dispose();
    }
    for (final warehouse in _warehouseDrafts) {
      warehouse.dispose();
    }
    super.dispose();
  }

  String _displayNameFromEmail(String email) {
    final localPart = email.split('@').first.trim();
    if (localPart.isEmpty) return 'Admin User';
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
    if (_isLogisticsRole(role)) return 'logistics';
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

  bool _isDealerOwner(String roleName) =>
      _canonicalRoleName(roleName) == 'dealer_owner';

  bool _isDealerStaff(String roleName) => {
    'dealer_manager',
    'dealer_inventory_staff',
    'dealer_finance_staff',
    'dealer_support_staff',
  }.contains(_canonicalRoleName(roleName));

  bool _isLogisticsRole(String roleName) => {
    'logistics_manager',
    'dispatcher',
    'fleet_manager',
    'warehouse_manager',
    'driver',
  }.contains(_canonicalRoleName(roleName));

  Color _roleColor(String? roleName) {
    final role = _canonicalRoleName(roleName);
    if (role.startsWith('dealer_')) return const Color(0xFFF59E0B);
    if (_isLogisticsRole(role)) return const Color(0xFF22D3EE);
    if (role == 'support_agent' || role == 'support_manager') {
      return const Color(0xFFA78BFA);
    }
    if (role.isEmpty) return const Color(0xFF64748B);
    return const Color(0xFF60A5FA);
  }

  IconData _roleIcon(String? roleName) {
    final role = _canonicalRoleName(roleName);
    if (role.startsWith('dealer_')) return Icons.storefront_outlined;
    if (_isLogisticsRole(role)) return Icons.warehouse_outlined;
    if (role == 'support_agent' || role == 'support_manager') {
      return Icons.support_agent_outlined;
    }
    return Icons.admin_panel_settings_outlined;
  }

  Role? _selectedRole(List<Role> roles) {
    for (final role in roles) {
      if (role.id == _selectedRoleId) return role;
    }
    return null;
  }

  void _syncStationDraftCount(int count) {
    while (_stationDrafts.length < count) {
      _stationDrafts.add(_StationDraft(_stationDrafts.length));
    }
    while (_stationDrafts.length > count) {
      _stationDrafts.removeLast().dispose();
    }
  }

  void _syncWarehouseDraftCount(int count) {
    while (_warehouseDrafts.length < count) {
      _warehouseDrafts.add(_WarehouseDraft(_warehouseDrafts.length));
    }
    while (_warehouseDrafts.length > count) {
      _warehouseDrafts.removeLast().dispose();
    }
  }

  void _handleRoleSelection(String roleId, List<Role> roles) {
    final role = roles.where((item) => item.id == roleId).firstOrNull;
    final canonicalRole = _canonicalRoleName(role?.name);
    setState(() {
      _selectedRoleId = roleId;
      _createdUser = null;
      if (!_isDealerStaff(canonicalRole)) {
        _selectedDealerId = null;
        _selectedStationIds.clear();
      }
      if (!_isDealerOwner(canonicalRole)) {
        _syncStationDraftCount(0);
      }
      if (!_isLogisticsRole(canonicalRole)) {
        _selectedWarehouseIds.clear();
        _syncWarehouseDraftCount(0);
      }
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFDC2626),
      ),
    );
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
      'phone_number': _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      'status': 'active',
      'role_id': roleId,
      'user_type': userType,
    };

    if (_isDealerOwner(canonicalRoleName)) {
      if (_stationDrafts.isEmpty) {
        throw StateError('Add at least one connected station for the dealer.');
      }
      payload['dealer_profile'] = {
        'business_name': _businessNameController.text.trim(),
        'contact_person': _dealerContactPersonController.text.trim().isEmpty
            ? fullName
            : _dealerContactPersonController.text.trim(),
        'contact_email': email,
        'contact_phone': _dealerContactPhoneController.text.trim(),
        'address_line1': _dealerAddressController.text.trim(),
        'city': _dealerCityController.text.trim(),
        'state': _dealerStateController.text.trim(),
        'pincode': _dealerPincodeController.text.trim(),
      };
      payload['stations_to_create'] = _stationDrafts
          .map((draft) => draft.toPayload())
          .toList();
    }

    if (_isDealerStaff(canonicalRoleName)) {
      if (_selectedDealerId == null) {
        throw StateError('Select a dealer for this staff user.');
      }
      if (_selectedStationIds.isEmpty) {
        throw StateError('Select at least one connected station.');
      }
      payload['dealer_id'] = _selectedDealerId;
      payload['station_ids'] = _selectedStationIds.toList()..sort();
    }

    if (_isLogisticsRole(canonicalRoleName)) {
      if (_selectedWarehouseIds.isNotEmpty) {
        payload['warehouse_ids'] = _selectedWarehouseIds.toList()..sort();
      }
      if (_warehouseDrafts.isNotEmpty) {
        payload['warehouses_to_create'] = _warehouseDrafts
            .map((draft) => draft.toPayload())
            .toList();
      }
    }

    return payload;
  }

  Future<void> _createUser() async {
    if (!_formKey.currentState!.validate()) return;
    final roles = ref.read(userCreationRolesProvider).valueOrNull ?? const [];
    final selectedRole = _selectedRole(roles);
    if (selectedRole == null) {
      _showError('Please select a role.');
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
      _showError('Failed to create user: $error');
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
            subtitle:
                'Provision users with their connected dealer stations or logistics warehouses.',
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
              final isWide = constraints.maxWidth >= 1100;
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
    final dealersAsync = ref.watch(userCreationDealersProvider);
    final stationsAsync = ref.watch(
      userCreationStationsProvider(_selectedDealerId),
    );
    final warehousesAsync = ref.watch(userCreationWarehousesProvider);

    final selectedRole = rolesAsync.valueOrNull == null
        ? null
        : _selectedRole(rolesAsync.valueOrNull!);
    final canonicalRoleName = _canonicalRoleName(selectedRole?.name);

    return AdvancedCard(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              icon: Icons.person_add_alt_1_rounded,
              title: 'Account Details',
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
            const SizedBox(height: 18),
            _buildTextField(
              controller: _phoneController,
              label: 'Phone',
              icon: Icons.phone_outlined,
              hintText: 'Optional',
              keyboardType: TextInputType.phone,
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
            if (_isDealerOwner(canonicalRoleName)) ...[
              const SizedBox(height: 28),
              _buildDealerProfileSection(),
              const SizedBox(height: 24),
              _buildStationProvisioningSection(),
            ],
            if (_isDealerStaff(canonicalRoleName)) ...[
              const SizedBox(height: 28),
              _buildDealerStaffAssignmentSection(dealersAsync, stationsAsync),
            ],
            if (_isLogisticsRole(canonicalRoleName)) ...[
              const SizedBox(height: 28),
              _buildWarehouseProvisioningSection(warehousesAsync),
            ],
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

  Widget _buildDealerProfileSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          icon: Icons.storefront_outlined,
          title: 'Dealer Profile',
        ),
        const SizedBox(height: 18),
        _buildTextField(
          controller: _businessNameController,
          label: 'Business Name',
          icon: Icons.business_outlined,
          validator: (value) => (value?.trim().isEmpty ?? true)
              ? 'Business name is required'
              : null,
        ),
        const SizedBox(height: 18),
        _buildTextField(
          controller: _dealerContactPersonController,
          label: 'Contact Person',
          icon: Icons.person_outline_rounded,
          hintText: _nameController.text.trim(),
        ),
        const SizedBox(height: 18),
        _buildTextField(
          controller: _dealerContactPhoneController,
          label: 'Dealer Contact Phone',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          validator: (value) => (value?.trim().isEmpty ?? true)
              ? 'Contact phone is required'
              : null,
        ),
        const SizedBox(height: 18),
        _buildTextField(
          controller: _dealerAddressController,
          label: 'Address',
          icon: Icons.location_on_outlined,
          validator: (value) =>
              (value?.trim().isEmpty ?? true) ? 'Address is required' : null,
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _dealerCityController,
                label: 'City',
                icon: Icons.location_city_outlined,
                validator: (value) =>
                    (value?.trim().isEmpty ?? true) ? 'City is required' : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                controller: _dealerStateController,
                label: 'State',
                icon: Icons.map_outlined,
                validator: (value) => (value?.trim().isEmpty ?? true)
                    ? 'State is required'
                    : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _buildTextField(
          controller: _dealerPincodeController,
          label: 'Pincode',
          icon: Icons.pin_drop_outlined,
          keyboardType: TextInputType.number,
          validator: (value) =>
              (value?.trim().isEmpty ?? true) ? 'Pincode is required' : null,
        ),
      ],
    );
  }

  Widget _buildStationProvisioningSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          icon: Icons.ev_station_outlined,
          title: 'Connected Stations',
        ),
        const SizedBox(height: 12),
        _buildCountPicker(
          label: 'Number of connected stations',
          value: _stationDrafts.length,
          onChanged: (value) {
            setState(() => _syncStationDraftCount(value));
          },
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < _stationDrafts.length; i++) ...[
          _buildStationDraftCard(i, _stationDrafts[i]),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildStationDraftCard(int index, _StationDraft draft) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Station ${index + 1}',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: draft.nameController,
            label: 'Station Name',
            icon: Icons.ev_station_outlined,
            validator: (value) => (value?.trim().isEmpty ?? true)
                ? 'Station name is required'
                : null,
          ),
          const SizedBox(height: 14),
          _buildTextField(
            controller: draft.addressController,
            label: 'Address',
            icon: Icons.location_on_outlined,
            validator: (value) =>
                (value?.trim().isEmpty ?? true) ? 'Address is required' : null,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: draft.cityController,
                  label: 'City',
                  icon: Icons.location_city_outlined,
                  validator: (value) => (value?.trim().isEmpty ?? true)
                      ? 'City is required'
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDropdownField<String>(
                  label: 'Station Type',
                  value: draft.stationType,
                  items: const ['automated', 'manual', 'hybrid'],
                  icon: Icons.settings_outlined,
                  onChanged: (value) {
                    setState(() => draft.stationType = value ?? 'automated');
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: draft.latitudeController,
                  label: 'Latitude',
                  icon: Icons.my_location_outlined,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) =>
                      double.tryParse(value?.trim() ?? '') == null
                      ? 'Valid latitude required'
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: draft.longitudeController,
                  label: 'Longitude',
                  icon: Icons.explore_outlined,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) =>
                      double.tryParse(value?.trim() ?? '') == null
                      ? 'Valid longitude required'
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: draft.totalSlotsController,
                  label: 'Total Slots',
                  icon: Icons.grid_view_outlined,
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                      int.tryParse(value?.trim() ?? '') == null
                      ? 'Valid slots required'
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: draft.contactPhoneController,
                  label: 'Contact Phone',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: draft.is24x7,
            onChanged: (value) => setState(() => draft.is24x7 = value),
            title: const Text(
              '24x7 station',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              'Mark this station as always open',
              style: TextStyle(color: Colors.white54),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDealerStaffAssignmentSection(
    AsyncValue<List<Map<String, dynamic>>> dealersAsync,
    AsyncValue<List<Map<String, dynamic>>> stationsAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          icon: Icons.link_outlined,
          title: 'Dealer and Station Assignment',
        ),
        const SizedBox(height: 16),
        dealersAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => _buildAsyncError(
            message: 'Failed to load dealers: $error',
            onRetry: () => ref.invalidate(userCreationDealersProvider),
          ),
          data: (dealers) => _buildDropdownField<int>(
            label: 'Dealer',
            value: _selectedDealerId,
            items: dealers
                .map((dealer) => (dealer['id'] as num?)?.toInt())
                .whereType<int>()
                .toList(),
            icon: Icons.storefront_outlined,
            itemLabel: (id) {
              final dealer = dealers
                  .where((row) => row['id'] == id)
                  .firstOrNull;
              return dealer?['business_name']?.toString() ?? 'Dealer #$id';
            },
            onChanged: (value) {
              setState(() {
                _selectedDealerId = value;
                _selectedStationIds.clear();
              });
            },
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Connected Stations',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        if (_selectedDealerId == null)
          const Text(
            'Select a dealer first to load its stations.',
            style: TextStyle(color: Colors.white54),
          )
        else
          stationsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => _buildAsyncError(
              message: 'Failed to load stations: $error',
              onRetry: () => ref.invalidate(
                userCreationStationsProvider(_selectedDealerId),
              ),
            ),
            data: (stations) {
              if (stations.isEmpty) {
                return const Text(
                  'No stations are available for the selected dealer.',
                  style: TextStyle(color: Colors.white54),
                );
              }
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: stations.map((station) {
                  final stationId = (station['id'] as num?)?.toInt();
                  if (stationId == null) return const SizedBox.shrink();
                  return FilterChip(
                    selected: _selectedStationIds.contains(stationId),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedStationIds.add(stationId);
                        } else {
                          _selectedStationIds.remove(stationId);
                        }
                      });
                    },
                    label: Text(
                      station['name']?.toString() ?? 'Station #$stationId',
                    ),
                  );
                }).toList(),
              );
            },
          ),
      ],
    );
  }

  Widget _buildWarehouseProvisioningSection(
    AsyncValue<List<Map<String, dynamic>>> warehousesAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          icon: Icons.warehouse_outlined,
          title: 'Connected Warehouses',
        ),
        const SizedBox(height: 12),
        _buildCountPicker(
          label: 'Number of warehouses to create',
          value: _warehouseDrafts.length,
          onChanged: (value) {
            setState(() => _syncWarehouseDraftCount(value));
          },
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < _warehouseDrafts.length; i++) ...[
          _buildWarehouseDraftCard(i, _warehouseDrafts[i]),
          const SizedBox(height: 16),
        ],
        Text(
          'Attach Existing Warehouses',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        warehousesAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => _buildAsyncError(
            message: 'Failed to load warehouses: $error',
            onRetry: () => ref.invalidate(userCreationWarehousesProvider),
          ),
          data: (warehouses) {
            if (warehouses.isEmpty) {
              return const Text(
                'No existing warehouses available.',
                style: TextStyle(color: Colors.white54),
              );
            }
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: warehouses.map((warehouse) {
                final warehouseId = (warehouse['id'] as num?)?.toInt();
                if (warehouseId == null) return const SizedBox.shrink();
                final label =
                    '${warehouse['name'] ?? 'Warehouse #$warehouseId'} (${warehouse['code'] ?? 'N/A'})';
                return FilterChip(
                  selected: _selectedWarehouseIds.contains(warehouseId),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedWarehouseIds.add(warehouseId);
                      } else {
                        _selectedWarehouseIds.remove(warehouseId);
                      }
                    });
                  },
                  label: Text(label),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildWarehouseDraftCard(int index, _WarehouseDraft draft) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Warehouse ${index + 1}',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: draft.nameController,
            label: 'Warehouse Name',
            icon: Icons.warehouse_outlined,
            validator: (value) => (value?.trim().isEmpty ?? true)
                ? 'Warehouse name is required'
                : null,
          ),
          const SizedBox(height: 14),
          _buildTextField(
            controller: draft.codeController,
            label: 'Warehouse Code',
            icon: Icons.qr_code_2_outlined,
            validator: (value) =>
                (value?.trim().isEmpty ?? true) ? 'Code is required' : null,
          ),
          const SizedBox(height: 14),
          _buildTextField(
            controller: draft.addressController,
            label: 'Address',
            icon: Icons.location_on_outlined,
            validator: (value) =>
                (value?.trim().isEmpty ?? true) ? 'Address is required' : null,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: draft.cityController,
                  label: 'City',
                  icon: Icons.location_city_outlined,
                  validator: (value) => (value?.trim().isEmpty ?? true)
                      ? 'City is required'
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: draft.stateController,
                  label: 'State',
                  icon: Icons.map_outlined,
                  validator: (value) => (value?.trim().isEmpty ?? true)
                      ? 'State is required'
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildTextField(
            controller: draft.pincodeController,
            label: 'Pincode',
            icon: Icons.pin_drop_outlined,
            keyboardType: TextInputType.number,
            validator: (value) =>
                (value?.trim().isEmpty ?? true) ? 'Pincode is required' : null,
          ),
        ],
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

        final selectedRole = _selectedRole(roles);
        final selectedName = selectedRole?.name;

        return PopupMenuButton<String>(
          enabled: !_isSaving,
          color: const Color(0xFF1E293B),
          offset: const Offset(0, 58),
          constraints: const BoxConstraints(minWidth: 280, maxWidth: 420),
          onSelected: (roleId) => _handleRoleSelection(roleId, roles),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: resolvedColor.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: resolvedColor),
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
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
              ],
            ),
          ),
          trailing ?? const SizedBox.shrink(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({required IconData icon, required String title}) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF60A5FA)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCountPicker({
    required String label,
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    return _buildDropdownField<int>(
      label: label,
      value: value,
      items: List<int>.generate(6, (index) => index),
      icon: Icons.format_list_numbered_rounded,
      itemLabel: (item) => item.toString(),
      onChanged: (selected) => onChanged(selected ?? 0),
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required T? value,
    required List<T> items,
    required IconData icon,
    required ValueChanged<T?> onChanged,
    String Function(T item)? itemLabel,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      decoration: _inputDecoration(label: label, icon: icon),
      dropdownColor: const Color(0xFF1E293B),
      style: const TextStyle(color: Colors.white),
      iconEnabledColor: Colors.white54,
      items: items
          .map(
            (item) => DropdownMenuItem<T>(
              value: item,
              child: Text(
                itemLabel?.call(item) ?? item.toString(),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: _isSaving ? null : onChanged,
    );
  }

  Widget _buildAsyncError({
    required String message,
    required VoidCallback onRetry,
  }) {
    return AdvancedCard(
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFF59E0B)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message, style: const TextStyle(color: Colors.white70)),
          ),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Retry'),
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
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    Widget? suffixIcon,
    bool obscureText = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecoration(
        label: label,
        icon: icon,
        hintText: hintText,
        suffixIcon: suffixIcon,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? hintText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      suffixIcon: suffixIcon,
      labelStyle: const TextStyle(color: Colors.white70),
      hintStyle: const TextStyle(color: Colors.white30),
      prefixIcon: Icon(icon, color: Colors.white54),
      filled: true,
      fillColor: const Color(0xFF0F172A),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: Color(0xFF3B82F6)),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: Color(0xFFDC2626)),
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: Color(0xFFDC2626)),
      ),
    );
  }

  Widget _buildPreviewPanel() {
    final roles = ref.watch(userCreationRolesProvider).valueOrNull ?? const [];
    final role = _selectedRole(roles);
    final canonicalRole = _canonicalRoleName(role?.name);

    return AdvancedCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Provisioning Preview',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          _previewRow(
            'Role',
            role == null ? 'Not selected' : _displayRoleName(role.name),
          ),
          _previewRow(
            'Identity',
            _emailController.text.trim().isEmpty
                ? 'Pending email'
                : _emailController.text.trim(),
          ),
          if (_isDealerOwner(canonicalRole)) ...[
            _previewRow(
              'Dealer',
              _businessNameController.text.trim().isEmpty
                  ? 'Pending business name'
                  : _businessNameController.text.trim(),
            ),
            _previewRow('New Stations', _stationDrafts.length.toString()),
          ],
          if (_isDealerStaff(canonicalRole)) ...[
            _previewRow(
              'Dealer Id',
              _selectedDealerId?.toString() ?? 'Not selected',
            ),
            _previewRow(
              'Selected Stations',
              _selectedStationIds.length.toString(),
            ),
          ],
          if (_isLogisticsRole(canonicalRole)) ...[
            _previewRow('New Warehouses', _warehouseDrafts.length.toString()),
            _previewRow(
              'Existing Warehouses',
              _selectedWarehouseIds.length.toString(),
            ),
          ],
          if (_createdUser != null) ...[
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF052E16),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF16A34A)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Last Created User',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _previewRow('User Id', '${_createdUser!['id'] ?? '-'}'),
                  _previewRow(
                    'Dealer Id',
                    '${_createdUser!['dealer_id'] ?? '-'}',
                  ),
                  _previewRow(
                    'Created Stations',
                    '${(_createdUser!['created_station_ids'] as List?)?.length ?? 0}',
                  ),
                  _previewRow(
                    'Created Warehouses',
                    '${(_createdUser!['created_warehouse_ids'] as List?)?.length ?? 0}',
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _previewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 132,
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
            ),
          ),
        ],
      ),
    );
  }
}
