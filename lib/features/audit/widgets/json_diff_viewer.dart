import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class JsonDiffViewer extends StatelessWidget {
  final String? oldValue;
  final String? newValue;

  const JsonDiffViewer({super.key, this.oldValue, this.newValue});

  @override
  Widget build(BuildContext context) {
    final oldJson = _parseJson(oldValue);
    final newJson = _parseJson(newValue);

    if (oldJson == null && newJson == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: const Center(child: Text('No structured data changes recorded for this event.', style: TextStyle(color: Colors.white24, fontSize: 13))),
      );
    }

    final allKeys = {...(oldJson?.keys ?? []), ...(newJson?.keys ?? [])}.toList()..sort();
    final changedKeys = allKeys.where((key) => oldJson?[key] != newJson?[key]).toList();

    if (changedKeys.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.02), borderRadius: BorderRadius.circular(12)),
        child: const Center(child: Text('No property changes detected.', style: TextStyle(color: Colors.white24, fontSize: 13))),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: changedKeys.map((key) {
        final oldVal = oldJson?[key];
        final newVal = newJson?[key];

        return _buildDiffTile(key, oldVal, newVal);
      }).toList(),
    );
  }

  Widget _buildDiffTile(String key, dynamic oldVal, dynamic newVal) {
    bool isAdded = oldVal == null;
    bool isRemoved = newVal == null;
    
    Color accentColor = isAdded ? Colors.greenAccent : isRemoved ? Colors.redAccent : Colors.blueAccent;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withValues(alpha: 0.1)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.05), border: Border(bottom: BorderSide(color: accentColor.withValues(alpha: 0.1)))),
            child: Row(
              children: [
                Icon(isAdded ? Icons.add_box_outlined : isRemoved ? Icons.indeterminate_check_box_outlined : Icons.edit_note, size: 14, color: accentColor),
                const SizedBox(width: 8),
                Text(key.toUpperCase(), style: GoogleFonts.robotoMono(fontSize: 11, fontWeight: FontWeight.bold, color: accentColor, letterSpacing: 1)),
                const Spacer(),
                Text(isAdded ? 'ADDED' : isRemoved ? 'REMOVED' : 'CHANGED', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w900, color: accentColor.withValues(alpha: 0.5))),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isAdded)
                  Expanded(
                    child: _valueDisplay(oldVal, Colors.redAccent, 'OLD VALUE'),
                  ),
                if (!isAdded && !isRemoved)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Icon(Icons.arrow_forward_rounded, color: Colors.white.withValues(alpha: 0.1), size: 20),
                  ),
                if (!isRemoved)
                  Expanded(
                    child: _valueDisplay(newVal, Colors.greenAccent, isAdded ? 'VALUE' : 'NEW VALUE'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _valueDisplay(dynamic value, Color color, String label) {
    String displayValue = value is Map || value is List ? const JsonEncoder.withIndent('  ').convert(value) : value.toString();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 9, color: Colors.white24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.1)),
          ),
          child: Text(
            displayValue,
            style: GoogleFonts.firaCode(fontSize: 12, color: color.withValues(alpha: 0.8), height: 1.5),
          ),
        ),
      ],
    );
  }

  Map<String, dynamic>? _parseJson(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      final decoded = jsonDecode(value);
      if (decoded is Map<String, dynamic>) return decoded;
      return {'value': decoded};
    } catch (_) {
      return {'value': value};
    }
  }
}
