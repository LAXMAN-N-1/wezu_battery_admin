import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../data/models/feature_flag_model.dart';

class FlagDetailsDrawer extends StatelessWidget {
  final FeatureFlagModel flag;

  const FlagDetailsDrawer({super.key, required this.flag});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 450,
      backgroundColor: const Color(0xFF0F172A),
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(24), bottomLeft: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Description'),
                  const SizedBox(height: 12),
                  Text(flag.description, style: GoogleFonts.inter(fontSize: 14, color: Colors.white70, height: 1.6)),
                  const SizedBox(height: 32),
                  
                  _buildSectionHeader('Affected Systems'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: flag.affectedApps.map((app) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(6)),
                      child: Text(app, style: GoogleFonts.inter(fontSize: 12, color: Colors.white)),
                    )).toList(),
                  ),
                  const SizedBox(height: 32),
                  
                  _buildSectionHeader('Environment Overrides'),
                  const SizedBox(height: 12),
                  _buildOverridesTable(),
                  const SizedBox(height: 32),
                  
                  _buildSectionHeader('Audit History'),
                  const SizedBox(height: 16),
                  _buildHistoryTimeline(),
                ],
              ),
            ),
          ),
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(32, 48, 24, 24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFF3B82F6).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                      child: Text(flag.category.label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF3B82F6))),
                    ),
                    const SizedBox(width: 8),
                    Text(flag.key, style: GoogleFonts.robotoMono(fontSize: 10, color: Colors.white24)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(flag.name, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.white54),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white38, letterSpacing: 1.2),
    );
  }

  Widget _buildOverridesTable() {
    final envs = ['Production', 'Staging', 'Dev'];
    return Column(
      children: envs.map((env) {
        final val = flag.overrides[env] ?? flag.isEnabled;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(env, style: GoogleFonts.inter(fontSize: 13, color: Colors.white)),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: val ? Colors.green : Colors.red),
                  ),
                  const SizedBox(width: 8),
                  Text(val ? 'ON' : 'OFF', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: val ? Colors.green : Colors.red)),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHistoryTimeline() {
    if (flag.history.isEmpty) {
      return Text('No changes recorded yet.', style: GoogleFonts.inter(fontSize: 13, color: Colors.white24));
    }

    return Column(
      children: flag.history.map((entry) => Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(width: 12, height: 12, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF3B82F6), width: 2))),
                Container(width: 2, height: 50, color: Colors.white.withOpacity(0.05)),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(entry.changedBy, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                      Text(DateFormat('MMM dd, HH:mm').format(entry.timestamp), style: GoogleFonts.inter(fontSize: 11, color: Colors.white24)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.white54),
                      children: [
                        const TextSpan(text: 'Changed status from '),
                        TextSpan(text: entry.oldValue ? 'ON' : 'OFF', style: TextStyle(color: entry.oldValue ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
                        const TextSpan(text: ' to '),
                        TextSpan(text: entry.newValue ? 'ON' : 'OFF', style: TextStyle(color: entry.newValue ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  if (entry.comment != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      width: double.infinity,
                      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                      child: Text('"${entry.comment}"', style: GoogleFonts.inter(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.white38)),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      ),
      child: Column(
        children: [
           Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Last modified by', style: GoogleFonts.inter(fontSize: 11, color: Colors.white24)),
              Text(flag.lastChangedBy, style: GoogleFonts.inter(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Last modified at', style: GoogleFonts.inter(fontSize: 11, color: Colors.white24)),
              Text(DateFormat('yyyy-MM-dd HH:mm').format(flag.lastChangedAt), style: GoogleFonts.inter(fontSize: 11, color: Colors.white70)),
            ],
          ),
        ],
      ),
    );
  }
}
