import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/models/station.dart';
import '../data/providers/stations_provider.dart';

// Country code configuration with phone number length rules
class _CountryCode {
  final String flag;
  final String name;
  final String dialCode;
  final int phoneLength; // expected digits after the dial code

  const _CountryCode({
    required this.flag,
    required this.name,
    required this.dialCode,
    required this.phoneLength,
  });
}

const List<_CountryCode> _countryCodes = [
  _CountryCode(flag: '🇮🇳', name: 'India', dialCode: '+91', phoneLength: 10),
  _CountryCode(flag: '🇺🇸', name: 'USA', dialCode: '+1', phoneLength: 10),
  _CountryCode(flag: '🇬🇧', name: 'UK', dialCode: '+44', phoneLength: 10),
  _CountryCode(flag: '🇦🇪', name: 'UAE', dialCode: '+971', phoneLength: 9),
  _CountryCode(
    flag: '🇸🇦',
    name: 'Saudi Arabia',
    dialCode: '+966',
    phoneLength: 9,
  ),
  _CountryCode(
    flag: '🇸🇬',
    name: 'Singapore',
    dialCode: '+65',
    phoneLength: 8,
  ),
  _CountryCode(
    flag: '🇦🇺',
    name: 'Australia',
    dialCode: '+61',
    phoneLength: 9,
  ),
  _CountryCode(flag: '🇩🇪', name: 'Germany', dialCode: '+49', phoneLength: 11),
  _CountryCode(flag: '🇫🇷', name: 'France', dialCode: '+33', phoneLength: 9),
  _CountryCode(flag: '🇯🇵', name: 'Japan', dialCode: '+81', phoneLength: 10),
];

class StationFormDialog extends ConsumerStatefulWidget {
  final Station? station;

  const StationFormDialog({super.key, this.station});

  @override
  ConsumerState<StationFormDialog> createState() => _StationFormDialogState();
}

class _StationFormDialogState extends ConsumerState<StationFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _latController;
  late TextEditingController _lngController;
  late TextEditingController _capacityController;
  late TextEditingController _phoneController;

  String _status = 'active';
  _CountryCode _selectedCountry = _countryCodes.first; // Default: India +91

  @override
  void initState() {
    super.initState();
    final station = widget.station;
    _nameController = TextEditingController(text: station?.name ?? '');
    _addressController = TextEditingController(text: station?.address ?? '');
    _latController = TextEditingController(
      text: station?.latitude.toString() ?? '',
    );
    _lngController = TextEditingController(
      text: station?.longitude.toString() ?? '',
    );
    _capacityController = TextEditingController(
      text:
          station?.capacity?.toString() ?? station?.totalSlots.toString() ?? '',
    );
    _status = station?.status ?? 'active';

    // Parse existing phone to extract country code and number
    final existingPhone = station?.contactPhone ?? '';
    if (existingPhone.isNotEmpty) {
      // Try to match a known dial code
      _CountryCode? matched;
      for (final c in _countryCodes) {
        if (existingPhone.startsWith(c.dialCode)) {
          matched = c;
          break;
        }
      }
      if (matched != null) {
        _selectedCountry = matched;
        _phoneController = TextEditingController(
          text: existingPhone.substring(matched.dialCode.length).trim(),
        );
      } else {
        _phoneController = TextEditingController(text: existingPhone);
      }
    } else {
      _phoneController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _capacityController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text;
      final address = _addressController.text;
      final lat = double.tryParse(_latController.text) ?? 0.0;
      final lng = double.tryParse(_lngController.text) ?? 0.0;
      final capacity = int.tryParse(_capacityController.text) ?? 0;
      final phone = _phoneController.text.isNotEmpty
          ? '${_selectedCountry.dialCode} ${_phoneController.text}'
          : '';

      final station = Station(
        id: widget.station?.id ?? 0,
        name: name,
        address: address,
        latitude: lat,
        longitude: lng,
        status: _status,
        totalSlots: capacity,
        availableBatteries: widget.station?.availableBatteries ?? 0,
        // Recalculate emptySlots whenever capacity changes
        emptySlots: capacity - (widget.station?.availableBatteries ?? 0),
        lastPing: widget.station?.lastPing ?? DateTime.now(),
        createdAt: widget.station?.createdAt ?? DateTime.now(),
        capacity: capacity,
        contactPhone: phone,
      );

      try {
        if (widget.station == null) {
          await ref.read(stationsProvider.notifier).addStation(station);
        } else {
          await ref.read(stationsProvider.notifier).updateStation(station);
        }
        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceAll('Exception: ', '')),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth < 600 ? screenWidth * 0.95 : 500.0;

    return Dialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
      child: Container(
        width: dialogWidth,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.station == null ? 'Add New Station' : 'Edit Station',
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),

                _buildTextField(
                  'Station Name',
                  _nameController,
                  required: true,
                ),
                const SizedBox(height: 14),
                _buildTextField('Address', _addressController, required: true),
                const SizedBox(height: 14),

                // Lat / Lng row
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        'Latitude',
                        _latController,
                        required: true,
                        isNumber: true,
                        validator: (v) {
                          final parsed = double.tryParse(v ?? '');
                          if (parsed == null || parsed < -90 || parsed > 90) {
                            return 'Invalid (-90 to 90)';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        'Longitude',
                        _lngController,
                        required: true,
                        isNumber: true,
                        validator: (v) {
                          final parsed = double.tryParse(v ?? '');
                          if (parsed == null || parsed < -180 || parsed > 180) {
                            return 'Invalid (-180 to 180)';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Capacity / Status row — fixed with Flexible to prevent overflow
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(
                      flex: 1,
                      child: _buildTextField(
                        'Capacity (Slots)',
                        _capacityController,
                        required: true,
                        isNumber: true,
                        isInteger: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Status',
                            style: GoogleFonts.inter(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            initialValue: _status,
                            isExpanded: true, // prevents overflow
                            dropdownColor: const Color(0xFF1E293B),
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.black.withValues(alpha: 0.2),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 14,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'active',
                                child: Text('Active'),
                              ),
                              DropdownMenuItem(
                                value: 'maintenance',
                                child: Text('Maintenance'),
                              ),
                              DropdownMenuItem(
                                value: 'inactive',
                                child: Text('Inactive'),
                              ),
                            ],
                            onChanged: (v) => setState(() => _status = v!),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Phone field with country code selector
                _buildPhoneField(),
                const SizedBox(height: 28),

                // Action buttons
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        widget.station == null ? 'Create' : 'Save Changes',
                      ),
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

  Widget _buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Contact Phone',
          style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Country code selector
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: PopupMenuButton<_CountryCode>(
                initialValue: _selectedCountry,
                color: const Color(0xFF1E293B),
                tooltip: 'Select country',
                onSelected: (c) => setState(() {
                  _selectedCountry = c;
                  _phoneController.clear();
                }),
                itemBuilder: (_) => _countryCodes
                    .map(
                      (c) => PopupMenuItem(
                        value: c,
                        child: Text(
                          '${c.flag}  ${c.dialCode}  ${c.name}',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 14,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${_selectedCountry.flag} ${_selectedCountry.dialCode}',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_drop_down,
                        color: Colors.white54,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Number input
            Expanded(
              child: TextFormField(
                controller: _phoneController,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(
                    _selectedCountry.phoneLength,
                  ),
                ],
                decoration: InputDecoration(
                  hintText:
                      '${'#' * _selectedCountry.phoneLength}  (${_selectedCountry.phoneLength} digits)',
                  hintStyle: GoogleFonts.inter(
                    color: Colors.white24,
                    fontSize: 13,
                  ),
                  filled: true,
                  fillColor: Colors.black.withValues(alpha: 0.2),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return null; // optional field
                  }
                  if (value.length != _selectedCountry.phoneLength) {
                    return 'Must be ${_selectedCountry.phoneLength} digits for ${_selectedCountry.dialCode}';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool required = false,
    bool isNumber = false,
    bool isInteger = false,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label + (required ? ' *' : ''),
          style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
          keyboardType: isNumber
              ? (isInteger
                    ? TextInputType.number
                    : const TextInputType.numberWithOptions(decimal: true))
              : TextInputType.text,
          inputFormatters: isInteger
              ? [FilteringTextInputFormatter.digitsOnly]
              : null,
          validator: (value) {
            if (required && (value == null || value.isEmpty)) {
              return 'This field is required';
            }
            if (validator != null) return validator(value);
            return null;
          },
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.black.withValues(alpha: 0.2),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
