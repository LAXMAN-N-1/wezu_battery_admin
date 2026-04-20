import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend_admin/core/utils/safe_state.dart';

class TransitionStateDialog extends StatefulWidget {
  final String userName;
  final String currentStatus;
  final Function(String newStatus) onSubmit;

  const TransitionStateDialog({
    super.key,
    required this.userName,
    required this.currentStatus,
    required this.onSubmit,
  });

  @override
  State<TransitionStateDialog> createState() => _TransitionStateDialogState();
}

class _TransitionStateDialogState extends SafeState<TransitionStateDialog> {
  late String _selectedStatus;

  @override
  void initState() {
    super.initState();
    _selectedStatus = _getPossibleTransitions().first;
  }

  List<String> _getPossibleTransitions() {
    // Valid transitions: PENDING → VERIFIED → ACTIVE, ACTIVE → SUSPENDED, SUSPENDED → ACTIVE/DELETED.
    if (widget.currentStatus.toUpperCase() == 'PENDING') return ['VERIFIED'];
    if (widget.currentStatus.toUpperCase() == 'VERIFIED') return ['ACTIVE'];
    if (widget.currentStatus.toUpperCase() == 'ACTIVE') return ['SUSPENDED'];
    if (widget.currentStatus.toUpperCase() == 'SUSPENDED') return ['ACTIVE', 'DELETED'];
    return ['ACTIVE', 'INACTIVE', 'SUSPENDED', 'PENDING', 'VERIFIED']; // Fallback
  }

  @override
  Widget build(BuildContext context) {
    final transitions = _getPossibleTransitions();
    return AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'Transition State',
        style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Change state for ${widget.userName}.\nCurrent: ${widget.currentStatus}',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            value: _selectedStatus,
            dropdownColor: const Color(0xFF1E293B),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'New New Status',
              labelStyle: const TextStyle(color: Colors.white54),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (v) {
              if (v != null) setState(() => _selectedStatus = v);
            },
            items: transitions.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onSubmit(_selectedStatus);
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Confirm Transition'),
        ),
      ],
    );
  }
}
