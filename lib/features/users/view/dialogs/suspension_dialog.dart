import 'package:flutter/material.dart';
import 'package:frontend_admin/core/utils/safe_state.dart';

class SuspensionDialog extends StatefulWidget {
  final String userName;
  final bool isSuspended;
  final Function(String reason, DateTime? until)? onSuspend;
  final VoidCallback? onReactivate;

  const SuspensionDialog({
    super.key,
    required this.userName,
    required this.isSuspended,
    this.onSuspend,
    this.onReactivate,
  });

  @override
  State<SuspensionDialog> createState() => _SuspensionDialogState();
}

class _SuspensionDialogState extends SafeState<SuspensionDialog> {
  final _reasonController = TextEditingController();
  int? _days;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isSuspended) {
      return AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text('Reactivate ${widget.userName}?', style: const TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to restore access?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              widget.onReactivate?.call();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Reactivate', style: TextStyle(color: Colors.white)),
          ),
        ],
      );
    }

    return AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      title: Text('Suspend ${widget.userName}', style: const TextStyle(color: Colors.white)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Provide a reason for suspending this user.', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 16),
          TextField(
            controller: _reasonController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Reason',
              labelStyle: TextStyle(color: Colors.white54),
              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white38)),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int?>(
            initialValue: _days,
            dropdownColor: const Color(0xFF1E293B),
            decoration: const InputDecoration(
              labelText: 'Duration',
              labelStyle: TextStyle(color: Colors.white54),
              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white38)),
            ),
            style: const TextStyle(color: Colors.white),
            items: const [
              DropdownMenuItem(value: null, child: Text('Indefinite')),
              DropdownMenuItem(value: 1, child: Text('24 Hours')),
              DropdownMenuItem(value: 3, child: Text('3 Days')),
              DropdownMenuItem(value: 7, child: Text('1 Week')),
              DropdownMenuItem(value: 30, child: Text('1 Month')),
            ],
            onChanged: (v) => setState(() => _days = v),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            if (_reasonController.text.isNotEmpty) {
              final until = _days != null ? DateTime.now().add(Duration(days: _days!)) : null;
              widget.onSuspend?.call(_reasonController.text, until);
              Navigator.pop(context);
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Suspend', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
