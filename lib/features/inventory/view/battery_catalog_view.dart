import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/admin_ui_components.dart';
import '../../../core/widgets/api_error_handler.dart';
import '../../auth/provider/auth_provider.dart';
import '../data/models/battery_catalog.dart';
import '../data/repositories/battery_catalog_repository.dart';

const _kBg = Color(0xFF0F172A);
const _kSurface = Color(0xFF1E293B);
const _kBlue = Color(0xFF3B82F6);
const _kGreen = Color(0xFF22C55E);
const _kAmber = Color(0xFFF59E0B);

class BatteryCatalogView extends ConsumerStatefulWidget {
  const BatteryCatalogView({super.key});

  @override
  ConsumerState<BatteryCatalogView> createState() => _BatteryCatalogViewState();
}

class _BatteryCatalogViewState extends ConsumerState<BatteryCatalogView> {
  final BatteryCatalogRepository _repository = BatteryCatalogRepository();
  final NumberFormat _inrWhole = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );
  final NumberFormat _inrDaily = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  final _batchFormKey = GlobalKey<FormState>();
  final _batchNumberCtrl = TextEditingController();
  final _batchPoCtrl = TextEditingController();
  final _batchQuantityCtrl = TextEditingController(text: '1');

  List<BatterySpecModel> _specs = [];
  bool _isLoadingSpecs = true;
  bool _isSubmittingBatch = false;
  int? _editingSpecId;
  String _search = '';

  int? _selectedSpecId;
  DateTime _manufacturerDate = DateTime.now();
  BatteryBatchModel? _lastCreatedBatch;

  @override
  void initState() {
    super.initState();
    _loadSpecs();
  }

  @override
  void dispose() {
    _batchNumberCtrl.dispose();
    _batchPoCtrl.dispose();
    _batchQuantityCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSpecs({bool showLoader = true}) async {
    if (showLoader) {
      setState(() => _isLoadingSpecs = true);
    }

    try {
      final specs = await _repository.listSpecs();
      if (!mounted) return;

      specs.sort((a, b) => b.id.compareTo(a.id));
      setState(() {
        _specs = specs;
        _selectedSpecId ??= specs.isNotEmpty ? specs.first.id : null;
        _isLoadingSpecs = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingSpecs = false);
      _showSnack(
        _readableError(e, fallback: 'Failed to load battery models.'),
        isError: true,
      );
    }
  }

  Future<void> _openCreateSpecDialog({required bool canManage}) async {
    if (!canManage) {
      _showSnack('Only superusers can create battery models.', isError: true);
      return;
    }

    final created = await showDialog<BatterySpecModel>(
      context: context,
      builder: (_) => _SpecFormDialog(repository: _repository),
    );

    if (created == null || !mounted) return;
    await _loadSpecs(showLoader: false);
    setState(() => _selectedSpecId = created.id);
  }

  Future<void> _openEditSpecDialog(
    BatterySpecModel row, {
    required bool canManage,
  }) async {
    if (!canManage) {
      _showSnack('Only superusers can update model pricing.', isError: true);
      return;
    }

    setState(() => _editingSpecId = row.id);
    try {
      final latest = await _repository.getSpec(row.id);
      if (!mounted) return;

      final updated = await showDialog<BatterySpecModel>(
        context: context,
        builder: (_) =>
            _SpecFormDialog(repository: _repository, initial: latest),
      );

      if (updated != null && mounted) {
        await _loadSpecs(showLoader: false);
      }
    } catch (e) {
      if (mounted) {
        _showSnack(
          _readableError(e, fallback: 'Unable to fetch model details.'),
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _editingSpecId = null);
      }
    }
  }

  Future<void> _submitBatch({required bool canManage}) async {
    if (!canManage) {
      _showSnack(
        'Only superusers can register procurement batches.',
        isError: true,
      );
      return;
    }

    if (!(_batchFormKey.currentState?.validate() ?? false)) return;
    if (_selectedSpecId == null) {
      _showSnack('Select a battery model first.', isError: true);
      return;
    }

    final payload = <String, dynamic>{
      'batch_number': _batchNumberCtrl.text.trim(),
      'quantity': int.parse(_batchQuantityCtrl.text.trim()),
      'manufacturer_date': _manufacturerDate.toUtc().toIso8601String(),
      'spec_id': _selectedSpecId,
    };

    final poRef = _batchPoCtrl.text.trim();
    if (poRef.isNotEmpty) payload['purchase_order_ref'] = poRef;

    setState(() => _isSubmittingBatch = true);
    try {
      final created = await _repository.createBatch(payload);
      if (!mounted) return;

      setState(() {
        _lastCreatedBatch = created;
        _isSubmittingBatch = false;
      });

      _batchNumberCtrl.clear();
      _batchPoCtrl.clear();
      _batchQuantityCtrl.text = '1';
      _manufacturerDate = DateTime.now();

      _showSnack('Batch ${created.batchNumber} registered successfully.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmittingBatch = false);
      _showSnack(
        _readableError(e, fallback: 'Failed to register procurement batch.'),
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final canManage = _isSuperuser(ref.watch(authProvider).user);

    return Container(
      color: _kBg,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            PageHeader(
              title: 'Battery Catalog & Pricing',
              subtitle:
                  'Manage battery models, rental/day pricing, and procurement batches.',
              actionButton: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => _loadSpecs(),
                    icon: const Icon(Icons.refresh, color: Colors.white70),
                    tooltip: 'Refresh models',
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () =>
                        _openCreateSpecDialog(canManage: canManage),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Model'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kBlue,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.white12,
                    ),
                  ),
                ],
              ),
            ),
            if (!canManage)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _kAmber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _kAmber.withValues(alpha: 0.4)),
                ),
                child: const Text(
                  'View access is available, but create/update actions are restricted to superusers.',
                  style: TextStyle(color: Color(0xFFFDE68A), fontSize: 13),
                ),
              ),
            Expanded(
              child: DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: const TabBar(
                        labelColor: _kBlue,
                        unselectedLabelColor: Colors.white54,
                        dividerColor: Colors.transparent,
                        tabs: [
                          Tab(text: 'Models & Prices'),
                          Tab(text: 'Register Batch'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildSpecsTab(canManage: canManage),
                          _buildBatchTab(canManage: canManage),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecsTab({required bool canManage}) {
    final filtered = _filteredSpecs();

    final avgPurchase = _specs.isEmpty
        ? 0.0
        : _specs.map((e) => e.priceFullPurchase).reduce((a, b) => a + b) /
              _specs.length;

    final avgDaily = _specs.isEmpty
        ? 0.0
        : _specs.map((e) => e.pricePerDay).reduce((a, b) => a + b) /
              _specs.length;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                onChanged: (v) => setState(() => _search = v.trim()),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search by name, brand, model, type',
                  hintStyle: const TextStyle(color: Colors.white38),
                  prefixIcon: const Icon(Icons.search, color: Colors.white38),
                  filled: true,
                  fillColor: _kSurface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            _statPill('Models', '${_specs.length}', Icons.inventory_2_outlined),
            const SizedBox(width: 8),
            _statPill('Avg/day', _inrDaily.format(avgDaily), Icons.schedule),
            const SizedBox(width: 8),
            _statPill(
              'Avg price',
              _inrWhole.format(avgPurchase),
              Icons.currency_rupee,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: AdvancedCard(
            padding: EdgeInsets.zero,
            child: _isLoadingSpecs
                ? const Center(child: CircularProgressIndicator())
                : _buildSpecsTable(filtered, canManage: canManage),
          ),
        ),
      ],
    );
  }

  Widget _buildBatchTab({required bool canManage}) {
    final selected = _specs.where((e) => e.id == _selectedSpecId).firstOrNull;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 1100;

        final formCard = AdvancedCard(
          child: Form(
            key: _batchFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Procurement Batch',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Register inbound stock batch. Dealer stock additions can auto-fill purchase cost from model full price.',
                  style: TextStyle(color: Colors.white60, fontSize: 12),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  key: ValueKey(_selectedSpecId),
                  initialValue: _selectedSpecId,
                  decoration: _inputDecoration('Battery Model'),
                  dropdownColor: _kSurface,
                  items: _specs
                      .map(
                        (s) => DropdownMenuItem<int>(
                          value: s.id,
                          child: Text(
                            '#${s.id}  ${s.name} • ${s.brand}',
                            style: const TextStyle(color: Colors.white),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _selectedSpecId = v),
                  validator: (v) => v == null ? 'Select a model' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _batchNumberCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Batch Number'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Batch number is required'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _batchPoCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration(
                    'Purchase Order Reference (optional)',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _batchQuantityCtrl,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration('Quantity'),
                  validator: (v) {
                    final qty = int.tryParse(v?.trim() ?? '');
                    if (qty == null || qty <= 0) {
                      return 'Enter a valid quantity';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final selectedDate = await showDatePicker(
                      context: context,
                      initialDate: _manufacturerDate,
                      firstDate: DateTime(2020, 1, 1),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                    );
                    if (selectedDate != null && mounted) {
                      setState(() => _manufacturerDate = selectedDate);
                    }
                  },
                  child: InputDecorator(
                    decoration: _inputDecoration('Manufacturer Date'),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat('dd MMM yyyy').format(_manufacturerDate),
                          style: const TextStyle(color: Colors.white),
                        ),
                        const Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Colors.white54,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmittingBatch
                        ? null
                        : () => _submitBatch(canManage: canManage),
                    icon: _isSubmittingBatch
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add_task),
                    label: Text(
                      _isSubmittingBatch
                          ? 'Registering...'
                          : 'Register Procurement Batch',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

        final infoCard = AdvancedCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pricing Flow Snapshot',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              _flowRow(
                'Model Purchase Price',
                selected == null
                    ? 'Select a model'
                    : _inrWhole.format(selected.priceFullPurchase),
              ),
              _flowRow(
                'Model Daily Rate',
                selected == null
                    ? 'Select a model'
                    : _inrDaily.format(selected.pricePerDay),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _kBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _kBlue.withValues(alpha: 0.35)),
                ),
                child: const Text(
                  'These prices propagate to rental daily calculations and dealer inventory valuation.',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
              const SizedBox(height: 16),
              if (_lastCreatedBatch != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _kGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _kGreen.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Last Created Batch',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Batch: ${_lastCreatedBatch!.batchNumber}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      Text(
                        'Quantity: ${_lastCreatedBatch!.quantity}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      Text(
                        'Spec ID: ${_lastCreatedBatch!.specId}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );

        if (isNarrow) {
          return ListView(
            children: [formCard, const SizedBox(height: 16), infoCard],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: formCard),
            const SizedBox(width: 16),
            Expanded(flex: 2, child: infoCard),
          ],
        );
      },
    );
  }

  Widget _buildSpecsTable(
    List<BatterySpecModel> rows, {
    required bool canManage,
  }) {
    if (rows.isEmpty) {
      return const Center(
        child: Text(
          'No battery models found.',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(
          Colors.white.withValues(alpha: 0.04),
        ),
        dataRowMinHeight: 52,
        columns: const [
          DataColumn(
            label: Text('ID', style: TextStyle(color: Colors.white70)),
          ),
          DataColumn(
            label: Text('MODEL', style: TextStyle(color: Colors.white70)),
          ),
          DataColumn(
            label: Text('TYPE', style: TextStyle(color: Colors.white70)),
          ),
          DataColumn(
            label: Text('VOLTAGE', style: TextStyle(color: Colors.white70)),
          ),
          DataColumn(
            label: Text('CAPACITY', style: TextStyle(color: Colors.white70)),
          ),
          DataColumn(
            label: Text('FULL PRICE', style: TextStyle(color: Colors.white70)),
          ),
          DataColumn(
            label: Text('DAY PRICE', style: TextStyle(color: Colors.white70)),
          ),
          DataColumn(
            label: Text('STATUS', style: TextStyle(color: Colors.white70)),
          ),
          DataColumn(
            label: Text('ACTIONS', style: TextStyle(color: Colors.white70)),
          ),
        ],
        rows: rows.map((spec) {
          return DataRow(
            cells: [
              DataCell(
                Text(
                  '#${spec.id}',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              DataCell(
                SizedBox(
                  width: 220,
                  child: Text(
                    '${spec.name} • ${spec.brand}',
                    style: const TextStyle(color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              DataCell(
                Text(
                  spec.batteryType ?? '—',
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
              DataCell(
                Text(
                  '${spec.voltage.toStringAsFixed(0)}V',
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
              DataCell(
                Text(
                  spec.capacityMah != null
                      ? '${spec.capacityMah!.toStringAsFixed(0)} mAh'
                      : (spec.capacityAh != null
                            ? '${spec.capacityAh!.toStringAsFixed(1)} Ah'
                            : '—'),
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
              DataCell(
                Text(
                  _inrWhole.format(spec.priceFullPurchase),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              DataCell(
                Text(
                  _inrDaily.format(spec.pricePerDay),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              DataCell(_statusChip(spec.isActive)),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: canManage
                          ? () =>
                                _openEditSpecDialog(spec, canManage: canManage)
                          : null,
                      tooltip: canManage
                          ? 'Edit fields and pricing'
                          : 'Superuser access required',
                      icon: _editingSpecId == spec.id
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.edit_outlined),
                      color: _kBlue,
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _statusChip(bool isActive) {
    final color = isActive ? _kGreen : const Color(0xFFEF4444);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        isActive ? 'ACTIVE' : 'INACTIVE',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _flowRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white60, fontSize: 13),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statPill(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _kBlue),
          const SizedBox(width: 6),
          Text(
            '$label: $value',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  List<BatterySpecModel> _filteredSpecs() {
    if (_search.isEmpty) return _specs;
    final q = _search.toLowerCase();
    return _specs.where((s) {
      final haystack = [
        s.name,
        s.brand,
        s.model ?? '',
        s.batteryType ?? '',
      ].join(' ').toLowerCase();
      return haystack.contains(q);
    }).toList();
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: _kSurface,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _kBlue),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  bool _isSuperuser(Map<String, dynamic>? user) {
    if (user == null) return false;
    if (user['is_superuser'] == true || user['isSuperuser'] == true) {
      return true;
    }

    final roles = <String>{};

    void addRole(dynamic value) {
      if (value is String && value.trim().isNotEmpty) {
        roles.add(value.toLowerCase().trim());
        return;
      }
      if (value is Iterable) {
        for (final item in value) {
          addRole(item);
        }
      }
    }

    addRole(user['role']);
    addRole(user['current_role']);
    addRole(user['roles']);
    addRole(user['available_roles']);

    final nested = user['user'];
    if (nested is Map) {
      if (nested['is_superuser'] == true || nested['isSuperuser'] == true) {
        return true;
      }
      addRole(nested['role']);
      addRole(nested['current_role']);
      addRole(nested['roles']);
      addRole(nested['user_type']);
    }

    return roles.contains('super_admin') || roles.contains('superadmin');
  }

  String _readableError(Object e, {required String fallback}) {
    if (e is DioException) return ApiErrorHandler.getReadableMessage(e);
    final msg = e.toString();
    if (msg.isEmpty) return fallback;
    return msg;
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : _kGreen,
      ),
    );
  }
}

class _SpecFormDialog extends StatefulWidget {
  final BatteryCatalogRepository repository;
  final BatterySpecModel? initial;

  const _SpecFormDialog({required this.repository, this.initial});

  @override
  State<_SpecFormDialog> createState() => _SpecFormDialogState();
}

class _SpecFormDialogState extends State<_SpecFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _brandCtrl;
  late final TextEditingController _modelCtrl;
  late final TextEditingController _voltageCtrl;
  late final TextEditingController _capacityMahCtrl;
  late final TextEditingController _cycleLifeCtrl;
  late final TextEditingController _warrantyMonthsCtrl;
  late final TextEditingController _batteryTypeCtrl;
  late final TextEditingController _fullPriceCtrl;
  late final TextEditingController _perDayCtrl;
  late final TextEditingController _descriptionCtrl;

  bool _isActive = true;
  bool _saving = false;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final s = widget.initial;

    _nameCtrl = TextEditingController(text: s?.name ?? '');
    _brandCtrl = TextEditingController(text: s?.brand ?? '');
    _modelCtrl = TextEditingController(text: s?.model ?? '');
    _voltageCtrl = TextEditingController(
      text: s?.voltage.toStringAsFixed(0) ?? '',
    );
    _capacityMahCtrl = TextEditingController(
      text: s?.capacityMah?.toStringAsFixed(0) ?? '',
    );
    _cycleLifeCtrl = TextEditingController(
      text: (s?.cycleLifeExpectancy ?? 1500).toString(),
    );
    _warrantyMonthsCtrl = TextEditingController(
      text: (s?.warrantyMonths ?? 0).toString(),
    );
    _batteryTypeCtrl = TextEditingController(text: s?.batteryType ?? '');
    _fullPriceCtrl = TextEditingController(
      text: (s?.priceFullPurchase ?? 0).toStringAsFixed(2),
    );
    _perDayCtrl = TextEditingController(
      text: (s?.pricePerDay ?? 0).toStringAsFixed(2),
    );
    _descriptionCtrl = TextEditingController(text: s?.description ?? '');
    _isActive = s?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _brandCtrl.dispose();
    _modelCtrl.dispose();
    _voltageCtrl.dispose();
    _capacityMahCtrl.dispose();
    _cycleLifeCtrl.dispose();
    _warrantyMonthsCtrl.dispose();
    _batteryTypeCtrl.dispose();
    _fullPriceCtrl.dispose();
    _perDayCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final payload = <String, dynamic>{
      'name': _nameCtrl.text.trim(),
      'brand': _brandCtrl.text.trim(),
      'voltage': double.tryParse(_voltageCtrl.text.trim()) ?? 0,
      'capacity_mah': double.tryParse(_capacityMahCtrl.text.trim()) ?? 0,
      'cycle_life_expectancy': int.tryParse(_cycleLifeCtrl.text.trim()) ?? 1500,
      'price_full_purchase': double.tryParse(_fullPriceCtrl.text.trim()) ?? 0,
      'price_per_day': double.tryParse(_perDayCtrl.text.trim()) ?? 0,
      'is_active': _isActive,
    };

    final model = _modelCtrl.text.trim();
    final type = _batteryTypeCtrl.text.trim();
    final desc = _descriptionCtrl.text.trim();
    final warranty = int.tryParse(_warrantyMonthsCtrl.text.trim());

    if (model.isNotEmpty) payload['model'] = model;
    if (type.isNotEmpty) payload['battery_type'] = type;
    if (desc.isNotEmpty) payload['description'] = desc;
    if (warranty != null && warranty >= 0) {
      payload['warranty_months'] = warranty;
    }

    setState(() => _saving = true);
    try {
      final result = _isEdit
          ? await widget.repository.updateSpec(widget.initial!.id, payload)
          : await widget.repository.createSpec(payload);

      if (!mounted) return;
      Navigator.of(context).pop(result);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      final message = e is DioException
          ? ApiErrorHandler.getReadableMessage(e)
          : 'Unable to save battery model.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF111827),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        _isEdit ? 'Update Battery Model & Pricing' : 'Create Battery Model',
        style: const TextStyle(color: Colors.white),
      ),
      content: SizedBox(
        width: 680,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _textField(_nameCtrl, 'Name', required: true),
                const SizedBox(height: 10),
                _textField(_brandCtrl, 'Brand', required: true),
                const SizedBox(height: 10),
                _textField(_modelCtrl, 'Model (optional)'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _textField(
                        _voltageCtrl,
                        'Voltage',
                        required: true,
                        number: true,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _textField(
                        _capacityMahCtrl,
                        'Capacity mAh',
                        required: true,
                        number: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _textField(
                        _fullPriceCtrl,
                        'Full Purchase Price (INR)',
                        required: true,
                        number: true,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _textField(
                        _perDayCtrl,
                        'Price / Day (INR)',
                        required: true,
                        number: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _textField(
                        _cycleLifeCtrl,
                        'Cycle Life',
                        number: true,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _textField(
                        _warrantyMonthsCtrl,
                        'Warranty Months',
                        number: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _textField(_batteryTypeCtrl, 'Battery Type (optional)'),
                const SizedBox(height: 10),
                _textField(
                  _descriptionCtrl,
                  'Description (optional)',
                  maxLines: 3,
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: _kBlue,
                  title: const Text(
                    'Model is Active',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: _kBlue,
            foregroundColor: Colors.white,
          ),
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_isEdit ? 'Save Changes' : 'Create Model'),
        ),
      ],
    );
  }

  Widget _textField(
    TextEditingController controller,
    String label, {
    bool required = false,
    bool number = false,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      keyboardType: number ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      validator: (v) {
        if (!required) return null;
        if (v == null || v.trim().isEmpty) return '$label is required';
        if (number && double.tryParse(v.trim()) == null) {
          return 'Enter a valid number';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: _kSurface,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kBlue),
        ),
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
