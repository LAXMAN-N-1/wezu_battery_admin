import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminResetPasswordDialog extends StatefulWidget {
  final String userName;
  final Function(String password) onSubmit;

  const AdminResetPasswordDialog({
    super.key,
    required this.userName,
    required this.onSubmit,
  });

  @override
  State<AdminResetPasswordDialog> createState() => _AdminResetPasswordDialogState();
}

class _AdminResetPasswordDialogState extends State<AdminResetPasswordDialog> {
  final _passwordController = TextEditingController(text: 'TempPass@123');
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'Reset Password',
        style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Set a new temporary password for ${widget.userName}. They will be forced to change it on their next login.',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'New Password',
              labelStyle: const TextStyle(color: Colors.white54),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white54,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
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
            if (_passwordController.text.isNotEmpty) {
              widget.onSubmit(_passwordController.text);
              Navigator.pop(context);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Reset Password'),
        ),
      ],
    );
  }
}
