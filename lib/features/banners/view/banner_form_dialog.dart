import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/banner_model.dart';

class BannerFormDialog extends StatefulWidget {
  final BannerModel? banner;

  const BannerFormDialog({super.key, this.banner});

  @override
  State<BannerFormDialog> createState() => _BannerFormDialogState();
}

class _BannerFormDialogState extends State<BannerFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _imageController;
  late TextEditingController _targetController;
  late DateTime _startDate;
  late DateTime _endDate;
  BannerType _selectedType = BannerType.promotional;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.banner?.title);
    _imageController = TextEditingController(text: widget.banner?.imageUrl);
    _targetController = TextEditingController(text: widget.banner?.targetScreen);
    _startDate = widget.banner?.startDate ?? DateTime.now();
    _endDate = widget.banner?.endDate ?? DateTime.now().add(const Duration(days: 30));
    _selectedType = widget.banner?.type ?? BannerType.promotional;
    _isActive = widget.banner?.isActive ?? true;
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.banner != null;

    return Dialog(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    isEditing ? 'Edit Banner' : 'Add New Banner',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  TextFormField(
                    controller: _titleController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: _inputDecoration('Title', 'Enter banner title'),
                    validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _imageController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: _inputDecoration('Image URL', 'https://example.com/banner.png'),
                    validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _targetController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: _inputDecoration('Target Screen', '/screen-route (Optional)'),
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _startDate,
                              firstDate: DateTime.now().subtract(const Duration(days: 365)),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: ColorScheme.dark(
                                      primary: AppColors.primary,
                                      surface: AppColors.surface,
                                      onSurface: AppColors.textPrimary,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (date != null) setState(() => _startDate = date);
                          },
                          child: InputDecorator(
                            decoration: _inputDecoration('Start Date', ''),
                            child: Text(
                              DateFormat.yMMMd().format(_startDate),
                              style: const TextStyle(color: AppColors.textPrimary),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _endDate,
                              firstDate: _startDate,
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: ColorScheme.dark(
                                      primary: AppColors.primary,
                                      surface: AppColors.surface,
                                      onSurface: AppColors.textPrimary,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (date != null) setState(() => _endDate = date);
                          },
                          child: InputDecorator(
                            decoration: _inputDecoration('End Date', ''),
                            child: Text(
                              DateFormat.yMMMd().format(_endDate),
                              style: const TextStyle(color: AppColors.textPrimary),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),

                  DropdownButtonFormField<BannerType>(
                    value: _selectedType,
                    decoration: _inputDecoration('Banner Type', ''),
                    dropdownColor: AppColors.surface,
                    style: const TextStyle(color: AppColors.textPrimary),
                    items: BannerType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type.label),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _selectedType = value);
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Switch(
                        value: _isActive,
                        onChanged: (val) => setState(() => _isActive = val),
                        activeThumbColor: AppColors.primary,
                      ),
                      const Text('Active', style: TextStyle(color: AppColors.textPrimary)),
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
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            final banner = BannerModel(
                              id: widget.banner?.id ?? 'BNR-${DateTime.now().millisecondsSinceEpoch}',
                              title: _titleController.text,
                              imageUrl: _imageController.text,
                              type: _selectedType,
                              isActive: _isActive,
                              startDate: _startDate,
                              endDate: _endDate,
                              targetScreen: _targetController.text.isEmpty ? null : _targetController.text,
                            );
                            Navigator.pop(context, banner);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(isEditing ? 'Save Changes' : 'Create Banner'),
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

  InputDecoration _inputDecoration(String label, String hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: AppColors.textSecondary),
      hintStyle: const TextStyle(color: AppColors.textTertiary),
      filled: true,
      fillColor: AppColors.background,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.error)),
    );
  }
}
