import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/responsive.dart';
import '../../../core/models/battery_model.dart';

class BatteryFormDialog extends StatefulWidget {
  final BatteryModel? battery;

  const BatteryFormDialog({super.key, this.battery});

  @override
  State<BatteryFormDialog> createState() => _BatteryFormDialogState();
}

class _BatteryFormDialogState extends State<BatteryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _serialController;
  late TextEditingController _cycleController;
  
  String _type = 'Li-ion 2kWh';
  BatteryStatus _status = BatteryStatus.inStation;
  double _health = 100.0;

  @override
  void initState() {
    super.initState();
    _serialController = TextEditingController(text: widget.battery?.serialNumber ?? '');
    _cycleController = TextEditingController(text: widget.battery?.cycleCount.toString() ?? '0');
    
    if (widget.battery != null) {
      _type = widget.battery!.type;
      _status = widget.battery!.status;
      _health = widget.battery!.health;
    }
  }

  @override
  void dispose() {
    _serialController.dispose();
    _cycleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.battery != null;

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: Responsive.isMobile(context) ? MediaQuery.of(context).size.width * 0.9 : 500,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEditing ? 'Edit Battery' : 'Register New Battery',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              
              Flex(
                direction: Responsive.isMobile(context) ? Axis.vertical : Axis.horizontal,
                children: [
                   // Type
                  if (Responsive.isMobile(context)) ...[
                    _buildTextField(
                      controller: _serialController,
                      label: 'Serial Number',
                      validator: (v) => v?.isEmpty ?? true ? 'Serial Number is required' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _type,
                      dropdownColor: AppColors.surface,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: _inputDecoration('Type'),
                      items: ['Li-ion 2kWh', 'Li-ion 1.5kWh', 'LiFePO4 2.5kWh'].map((t) => DropdownMenuItem(
                        value: t,
                        child: Text(t),
                      )).toList(),
                      onChanged: (v) => setState(() => _type = v!),
                    ),
                  ] else ...[
                    Expanded(
                      child: _buildTextField(
                        controller: _serialController,
                        label: 'Serial Number',
                        validator: (v) => v?.isEmpty ?? true ? 'Serial Number is required' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _type,
                        dropdownColor: AppColors.surface,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: _inputDecoration('Type'),
                        items: ['Li-ion 2kWh', 'Li-ion 1.5kWh', 'LiFePO4 2.5kWh'].map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(t),
                        )).toList(),
                        onChanged: (v) => setState(() => _type = v!),
                      ),
                    ),
                  ],
                ],
              ),
              
              const SizedBox(height: 16),

              Flex(
                direction: Responsive.isMobile(context) ? Axis.vertical : Axis.horizontal,
                children: [
                  if (Responsive.isMobile(context)) ...[
                    DropdownButtonFormField<BatteryStatus>(
                      value: _status,
                      dropdownColor: AppColors.surface,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: _inputDecoration('Status'),
                      items: BatteryStatus.values.map((s) => DropdownMenuItem(
                        value: s,
                        child: Text(s.label),
                      )).toList(),
                      onChanged: (v) => setState(() => _status = v!),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _cycleController,
                      label: 'Cycle Count',
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (int.tryParse(v) == null) return 'Invalid number';
                        return null;
                      }
                    ),
                  ] else ...[
                    Expanded(
                      child: DropdownButtonFormField<BatteryStatus>(
                        value: _status,
                        dropdownColor: AppColors.surface,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: _inputDecoration('Status'),
                        items: BatteryStatus.values.map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(s.label),
                        )).toList(),
                        onChanged: (v) => setState(() => _status = v!),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        controller: _cycleController,
                        label: 'Cycle Count',
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          if (int.tryParse(v) == null) return 'Invalid number';
                          return null;
                        }
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 16),
              const Text('State of Health (SoH)', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
               Slider(
                value: _health,
                min: 0,
                max: 100,
                divisions: 100,
                label: '${_health.round()}%',
                activeColor: _getHealthColor(_health),
                onChanged: (val) => setState(() => _health = val),
              ),
              Center(child: Text('${_health.round()}%', style: TextStyle(color: _getHealthColor(_health), fontWeight: FontWeight.bold))),

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
                    child: Text(isEditing ? 'Save Changes' : 'Register Battery'),
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

  Color _getHealthColor(double health) {
    if (health > 90) return Colors.green;
    if (health > 70) return Colors.orange;
    return Colors.red;
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
      fillColor: AppColors.background.withOpacity(0.5),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: _inputDecoration(label),
    );
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final battery = BatteryModel(
        id: widget.battery?.id ?? '', 
        serialNumber: _serialController.text,
        type: _type,
        health: _health,
        cycles: int.parse(_cycleController.text),
        status: _status,
        assignedStationId: _status == BatteryStatus.inStation ? 'STN-Temp' : null,
        assignedUserId: _status == BatteryStatus.inUse ? 'USR-Temp' : null,
        chargeLevel: widget.battery?.chargeLevel ?? 100.0,
      );
      
      Navigator.pop(context, battery);
    }
  }
}
