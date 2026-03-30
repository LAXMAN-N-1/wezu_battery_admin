import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/widgets/admin_ui_components.dart';

class AdminGroupsMasterView extends StatelessWidget {
  const AdminGroupsMasterView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              title: 'Admin Groups',
              subtitle: 'Organize users by regional or business-unit groups for streamlined access provisioning.',
              actionButton: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add_rounded, size: 20, color: Colors.white),
                label: const Text('Create Group', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _buildGroupCard('Hyderabad Hub', 'Telangana Region', 12, 'Active')),
                const SizedBox(width: 20),
                Expanded(child: _buildGroupCard('Bangalore Ops', 'Karnataka Region', 8, 'Active')),
                const SizedBox(width: 20),
                Expanded(child: _buildGroupCard('Delhi NCR', 'Northern Region', 15, 'Inactive')),
                const SizedBox(width: 20),
                Expanded(child: _buildGroupCard('Global HQ', 'All Regions', 4, 'Active')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupCard(String title, String desc, int memberCount, String status) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: status == 'Active' ? Colors.green.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(color: status == 'Active' ? Colors.greenAccent : Colors.grey, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              const Icon(Icons.more_vert, color: Colors.white54, size: 20),
            ],
          ),
          const SizedBox(height: 20),
          Text(title, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 4),
          Text(desc, style: const TextStyle(color: Colors.white54, fontSize: 13)),
          const SizedBox(height: 24),
          const Divider(color: Colors.white10),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               Row(
                 children: [
                   const Icon(Icons.group, size: 16, color: Colors.blueAccent),
                   const SizedBox(width: 8),
                   Text('$memberCount Members', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                 ],
               ),
               TextButton(
                 onPressed: () {},
                 child: const Text('Manage', style: TextStyle(color: Colors.blueAccent)),
               ),
            ],
          ),
        ],
      ),
    );
  }
}
