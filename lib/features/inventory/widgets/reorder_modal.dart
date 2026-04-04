import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/stock_repository.dart';
import '../data/models/stock.dart';
import '../../../core/widgets/admin_ui_components.dart';

class ReorderModal extends ConsumerStatefulWidget {
  final StationStock station;
  final StockForecast forecast;

  const ReorderModal({super.key, required this.station, required this.forecast});

  @override
  ConsumerState<ReorderModal> createState() => _ReorderModalState();
}

class _ReorderModalState extends ConsumerState<ReorderModal> {
  int _currentStep = 0;
  late TextEditingController _qtyController;
  late TextEditingController _reasonController;
  bool _isSubmitting = false;
  ReorderRequest? _createdRequest;

  @override
  void initState() {
    super.initState();
    _qtyController = TextEditingController(text: widget.forecast.recommendedReorder.toString());
    _reasonController = TextEditingController(text: 'Automated restock based on 30-day demand forecast.');
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  void _submit() async {
    setState(() => _isSubmitting = true);
    try {
      final qty = int.tryParse(_qtyController.text) ?? widget.forecast.recommendedReorder;
      final request = await ref.read(stockRepositoryProvider).createReorderRequest(
        widget.station.stationId,
        qty,
        reason: _reasonController.text,
      );
      
      if (mounted) {
        setState(() {
           _isSubmitting = false;
           _createdRequest = request;
           _currentStep = 2; // Moving to Success step
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red)
        );
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Create Reorder Request', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 24),
            
            // Stepper indicator
            if (_currentStep < 2)
              Row(
                children: [
                  Expanded(child: Container(height: 4, decoration: BoxDecoration(color: const Color(0xFF3B82F6), borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(width: 8),
                  Expanded(child: Container(height: 4, decoration: BoxDecoration(color: _currentStep >= 1 ? const Color(0xFF3B82F6) : Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(width: 8),
                  Expanded(child: Container(height: 4, decoration: BoxDecoration(color: _currentStep >= 2 ? const Color(0xFF3B82F6) : Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(2)))),
                ],
              ),
            if (_currentStep < 2) const SizedBox(height: 32),
            
            if (_currentStep == 0) _buildStep1() else if (_currentStep == 1) _buildStep2() else _buildStep3(),
            
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (_currentStep == 1)
                  TextButton(onPressed: () => setState(() => _currentStep = 0), child: const Text('Back', style: TextStyle(color: Colors.white54))),
                const SizedBox(width: 16),
                SizedBox(
                  width: 150,
                  height: 44,
                  child: AdminButton(
                    label: _currentStep == 0 ? 'Next' : (_currentStep == 1 ? 'Send Request' : 'Done'),
                    isLoading: _isSubmitting,
                    onPressed: () {
                      if (_currentStep == 0) {
                        setState(() => _currentStep = 1);
                      } else if (_currentStep == 1) {
                        _submit();
                      } else {
                        Navigator.pop(context);
                      }
                    },
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
          child: Row(
            children: [
              const Icon(Icons.storefront, color: Colors.white54),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Destination Station', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  Text(widget.station.stationName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Current Stock', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  Text('${widget.station.availableCount}', style: TextStyle(color: widget.station.isLowStock ? Colors.redAccent : Colors.green, fontWeight: FontWeight.bold)),
                ],
              )
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Requested Quantity', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _qtyController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      suffixText: 'batteries',
                      suffixStyle: const TextStyle(color: Colors.white54, fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: Colors.amber, size: 14),
                      const SizedBox(width: 4),
                      Text('Forecast recommends ${widget.forecast.recommendedReorder}', style: const TextStyle(color: Colors.amber, fontSize: 12)),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Urgency', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: widget.station.isLowStock ? 'Urgent' : 'Normal',
                    dropdownColor: const Color(0xFF0F172A),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Normal', child: Text('Normal Delivery (3-5 days)')),
                      DropdownMenuItem(value: 'Urgent', child: Text('Urgent (Next Day)')),
                      DropdownMenuItem(value: 'Critical', child: Text('Critical (Same Day)', style: TextStyle(color: Colors.redAccent))),
                    ],
                    onChanged: (val) {},
                  ),
                ],
              ),
            )
          ],
        )
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Confirm Logistics Order', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.3))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Deliver ${_qtyController.text} batteries to:', style: const TextStyle(color: Colors.white, fontSize: 18)),
              const SizedBox(height: 8),
              Text(widget.station.stationName, style: const TextStyle(color: Colors.white54)),
              Text(widget.station.address, style: const TextStyle(color: Colors.white54)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text('Additional Notes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _reasonController,
          maxLines: 3,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF0F172A),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Icon(Icons.notifications_active, color: Colors.blue, size: 16),
            const SizedBox(width: 8),
            Text(
              'This will send automated Email & SMS alerts to depot managers.',
              style: TextStyle(color: Colors.blue.withValues(alpha: 0.8), fontSize: 13),
            )
          ],
        )
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      children: [
        const Icon(Icons.check_circle, color: Colors.green, size: 64),
        const SizedBox(height: 24),
        const Text('Reorder Request Created!', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Text(
          'Your logistics request has been successfully generated and sent to the depot team. You can track this request in the Reorder History tab.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
        ),
        const SizedBox(height: 24),
        if (_createdRequest != null)
           Container(
             padding: const EdgeInsets.all(16),
             decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(8)),
             child: Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 const Text('Request ID:', style: TextStyle(color: Colors.white54)),
                 Text(_createdRequest!.id.split('-').first.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
               ],
             )
           )
      ],
    );
  }
}

