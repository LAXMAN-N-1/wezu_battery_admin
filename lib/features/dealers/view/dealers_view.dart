import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/admin_ui_components.dart';
import '../data/models/dealer.dart';
import '../data/repositories/dealer_repository.dart';

class DealersView extends StatefulWidget {
  const DealersView({super.key});

  @override
  State<DealersView> createState() => _DealersViewState();
}

class _DealersViewState extends State<DealersView> {
  final DealerRepository _repository = DealerRepository();
  List<DealerProfile> _dealers = [];
  DealerStats? _stats;
  bool _isLoading = true;
  String _searchQuery = '';
  String _cityFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      _repository.getDealers(
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        city: _cityFilter != 'all' ? _cityFilter : null,
      ),
      _repository.getDealerStats(),
    ]);

    setState(() {
      _dealers =
          (results[0] as Map<String, dynamic>)['dealers']
              as List<DealerProfile>;
      _stats = results[1] as DealerStats;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cities = _dealers.map((d) => d.city).toSet().toList()..sort();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'All Dealers',
            subtitle: 'View and manage active dealers in your network.',
            actionButton: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white70),
                  onPressed: _loadData,
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _showAddDealerDialog,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Dealer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1),

          // Stats Cards
          Row(
            children: [
              _buildStatCard(
                'Active Dealers',
                _stats?.totalActiveDealers.toString() ?? '0',
                Icons.handshake_outlined,
                const Color(0xFF3B82F6),
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                'Pending Onboardings',
                _stats?.pendingOnboardings.toString() ?? '0',
                Icons.hourglass_top_outlined,
                const Color(0xFFF59E0B),
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                'All-time Commissions',
                '₹${NumberFormat('#,##0.00').format(_stats?.totalCommissionsPaid ?? 0)}',
                Icons.payments_outlined,
                const Color(0xFF22C55E),
              ),
            ],
          ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideX(begin: -0.05),
          const SizedBox(height: 24),

          // Search & Filter Row
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  style: const TextStyle(color: Colors.white),
                  onChanged: (v) {
                    _searchQuery = v;
                    _loadData();
                  },
                  decoration: InputDecoration(
                    hintText: 'Search business name, contact person...',
                    hintStyle: const TextStyle(color: Colors.white38),
                    prefixIcon: const Icon(Icons.search, color: Colors.white38),
                    filled: true,
                    fillColor: const Color(0xFF1E293B),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _cityFilter,
                    dropdownColor: const Color(0xFF1E293B),
                    items: [
                      const DropdownMenuItem(
                        value: 'all',
                        child: Text(
                          'All Cities',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      ...cities.map(
                        (c) => DropdownMenuItem(
                          value: c,
                          child: Text(
                            c,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                    onChanged: (v) {
                      _cityFilter = v ?? 'all';
                      _loadData();
                    },
                  ),
                ),
              ),
            ],
          ).animate().fadeIn(duration: 400.ms, delay: 150.ms),
          const SizedBox(height: 24),

          // Dealers Table
          AdvancedCard(
                padding: EdgeInsets.zero,
                child: _isLoading
                    ? const SizedBox(
                        height: 300,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : _dealers.isEmpty
                    ? const SizedBox(
                        height: 300,
                        child: Center(
                          child: Text(
                            'No dealers found.',
                            style: TextStyle(color: Colors.white54),
                          ),
                        ),
                      )
                    : AdvancedTable(
                        columns: const [
                          'Business Name',
                          'City',
                          'Contact',
                          'GST / PAN',
                          'Status',
                          'Joined',
                          'Actions',
                        ],
                        rows: _dealers.map((d) {
                          return [
                            Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(
                                          0xFF3B82F6,
                                        ).withValues(alpha: 0.3),
                                        const Color(
                                          0xFF8B5CF6,
                                        ).withValues(alpha: 0.3),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Center(
                                    child: Text(
                                      d.businessName[0],
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        d.businessName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        d.contactEmail ?? '',
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
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on_outlined,
                                  color: Colors.white38,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  d.city,
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  d.contactPerson,
                                  style: const TextStyle(color: Colors.white),
                                ),
                                Text(
                                  d.contactPhone,
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  d.gstNumber ?? 'N/A',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  d.panNumber ?? 'N/A',
                                  style: const TextStyle(
                                    color: Colors.white38,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                            StatusBadge(
                              status: d.isActive ? 'Active' : 'Inactive',
                            ),
                            Text(
                              DateFormat('MMM dd, yyyy').format(d.createdAt),
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.visibility_outlined,
                                    size: 18,
                                    color: Colors.white54,
                                  ),
                                  tooltip: 'View Details',
                                  onPressed: () => _showDetailDialog(d),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    size: 18,
                                    color: Color(0xFF3B82F6),
                                  ),
                                  tooltip: 'Edit',
                                  onPressed: () => _showEditDialog(d),
                                ),
                              ],
                            ),
                          ];
                        }).toList(),
                        onRowTap: (i) => _showDetailDialog(_dealers[i]),
                      ),
              )
              .animate()
              .fadeIn(duration: 500.ms, delay: 200.ms)
              .slideY(begin: 0.05),
        ],
      ),
    );
  }

  void _showDetailDialog(DealerProfile d) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 520,
          padding: const EdgeInsets.all(32),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          d.businessName[0],
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            d.businessName,
                            style: GoogleFonts.outfit(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          StatusBadge(
                            status: d.isActive ? 'Active' : 'Inactive',
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const Divider(color: Colors.white12, height: 32),
                _detailSection('Contact Info', [
                  _detailRow(
                    Icons.person_outline,
                    'Contact Person',
                    d.contactPerson,
                  ),
                  _detailRow(
                    Icons.email_outlined,
                    'Email',
                    d.contactEmail ?? 'N/A',
                  ),
                  _detailRow(Icons.phone_outlined, 'Phone', d.contactPhone),
                ]),
                _detailSection('Location', [
                  _detailRow(
                    Icons.home_outlined,
                    'Address',
                    d.addressLine1 ?? 'N/A',
                  ),
                  _detailRow(Icons.location_city_outlined, 'City', d.city),
                  _detailRow(Icons.map_outlined, 'State', d.state ?? 'N/A'),
                  _detailRow(Icons.pin_outlined, 'Pincode', d.pincode ?? 'N/A'),
                ]),
                _detailSection('Compliance', [
                  _detailRow(
                    Icons.receipt_long_outlined,
                    'GST Number',
                    d.gstNumber ?? 'N/A',
                  ),
                  _detailRow(
                    Icons.credit_card,
                    'PAN Number',
                    d.panNumber ?? 'N/A',
                  ),
                ]),
                _detailSection('Other', [
                  _detailRow(
                    Icons.calendar_today_outlined,
                    'Joined',
                    DateFormat('MMM dd, yyyy').format(d.createdAt),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailSection(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 10,
              color: Colors.white38,
              letterSpacing: 1.5,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: Colors.white38, size: 16),
          const SizedBox(width: 12),
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddDealerDialog() => _showDealerFormDialog(null);
  void _showEditDialog(DealerProfile d) => _showDealerFormDialog(d);

  void _showDealerFormDialog(DealerProfile? dealer) {
    final isEdit = dealer != null;
    final bizCtrl = TextEditingController(text: dealer?.businessName ?? '');
    final contactCtrl = TextEditingController(
      text: dealer?.contactPerson ?? '',
    );
    final emailCtrl = TextEditingController(text: dealer?.contactEmail ?? '');
    final phoneCtrl = TextEditingController(text: dealer?.contactPhone ?? '');
    final cityCtrl = TextEditingController(text: dealer?.city ?? '');
    final stateCtrl = TextEditingController(text: dealer?.state ?? '');
    final addrCtrl = TextEditingController(text: dealer?.addressLine1 ?? '');
    final pinCtrl = TextEditingController(text: dealer?.pincode ?? '');
    final gstCtrl = TextEditingController(text: dealer?.gstNumber ?? '');
    final panCtrl = TextEditingController(text: dealer?.panNumber ?? '');

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 540,
          padding: const EdgeInsets.all(32),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEdit ? 'Edit Dealer' : 'Add New Dealer',
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isEdit
                      ? 'Update dealer profile information.'
                      : 'Register a new dealer partner.',
                  style: const TextStyle(color: Colors.white54),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: _formField('Business Name *', bizCtrl)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _formField('Contact Person *', contactCtrl),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _formField('Email *', emailCtrl)),
                    const SizedBox(width: 16),
                    Expanded(child: _formField('Phone *', phoneCtrl)),
                  ],
                ),
                const SizedBox(height: 16),
                _formField('Address', addrCtrl),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _formField('City *', cityCtrl)),
                    const SizedBox(width: 16),
                    Expanded(child: _formField('State *', stateCtrl)),
                    const SizedBox(width: 16),
                    Expanded(child: _formField('Pincode *', pinCtrl)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _formField('GST Number', gstCtrl)),
                    const SizedBox(width: 16),
                    Expanded(child: _formField('PAN Number', panCtrl)),
                  ],
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.white54),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () async {
                        final data = {
                          'business_name': bizCtrl.text,
                          'contact_person': contactCtrl.text,
                          'contact_email': emailCtrl.text,
                          'contact_phone': phoneCtrl.text,
                          'city': cityCtrl.text,
                          'state': stateCtrl.text,
                          'address_line1': addrCtrl.text,
                          'pincode': pinCtrl.text,
                          'gst_number': gstCtrl.text,
                          'pan_number': panCtrl.text,
                        };
                        bool success;
                        if (isEdit) {
                          success = await _repository.updateDealer(
                            dealer.id,
                            data,
                          );
                        } else {
                          success = await _repository.createDealer(data);
                        }
                        if (!ctx.mounted || !mounted) {
                          return;
                        }
                        if (success) {
                          Navigator.pop(ctx);
                          _loadData();
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text(
                                isEdit ? 'Dealer updated!' : 'Dealer created!',
                              ),
                              backgroundColor: const Color(0xFF22C55E),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(isEdit ? 'Save Changes' : 'Create Dealer'),
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

  Widget _formField(String label, TextEditingController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF1E293B),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: AdvancedCard(
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
