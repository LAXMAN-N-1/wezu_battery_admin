import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/models/notification_models.dart';
import '../data/repositories/notification_repository.dart';
import 'package:frontend_admin/core/utils/safe_state.dart';

class SendPushView extends StatefulWidget {
  const SendPushView({super.key});
  @override
  State<SendPushView> createState() => _SendPushViewState();
}

class _SendPushViewState extends SafeState<SendPushView> {
  final NotificationRepository _repo = NotificationRepository();
  List<PushCampaign> _campaigns = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _campaigns = await _repo.getCampaigns();
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Push Notifications',
                      style: GoogleFonts.outfit(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Create, schedule & track push notification campaigns',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showCreateDialog,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New Campaign'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Stats
          _buildStats(),
          const SizedBox(height: 24),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _campaigns.isEmpty
              ? _emptyState()
              : Column(children: _campaigns.map(_buildCampaignCard).toList()),
        ],
      ),
    );
  }

  Widget _buildStats() {
    final sent = _campaigns.where((c) => c.status == 'sent').length;
    final scheduled = _campaigns.where((c) => c.status == 'scheduled').length;
    final drafts = _campaigns.where((c) => c.status == 'draft').length;
    final totalDelivered = _campaigns.fold<int>(
      0,
      (s, c) => s + c.deliveredCount,
    );
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _statCard(
          'Total Campaigns',
          '${_campaigns.length}',
          Icons.campaign,
          const Color(0xFF3B82F6),
        ),
        _statCard('Sent', '$sent', Icons.send, const Color(0xFF10B981)),
        _statCard(
          'Scheduled',
          '$scheduled',
          Icons.schedule,
          const Color(0xFFF59E0B),
        ),
        _statCard(
          'Drafts',
          '$drafts',
          Icons.edit_note,
          const Color(0xFF8B5CF6),
        ),
        _statCard(
          'Total Delivered',
          '$totalDelivered',
          Icons.check_circle,
          const Color(0xFF10B981),
        ),
      ],
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            title,
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildCampaignCard(PushCampaign c) {
    final statusColor = c.status == 'sent'
        ? Colors.green
        : c.status == 'scheduled'
        ? Colors.amber
        : c.status == 'draft'
        ? Colors.grey
        : Colors.blue;
    final openRate = c.sentCount > 0 ? (c.openCount / c.sentCount * 100) : 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  c.title,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  c.status.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (c.status == 'draft') ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    Icons.send,
                    color: Colors.green.shade400,
                    size: 20,
                  ),
                  onPressed: () => _sendCampaign(c.id),
                ),
              ],
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                  size: 20,
                ),
                onPressed: () => _deleteCampaign(c.id),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            c.message,
            style: TextStyle(color: Colors.white54, fontSize: 13),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _metricChip(
                'Channel',
                c.channel.toUpperCase(),
                Icons.notifications,
              ),
              const SizedBox(width: 12),
              _metricChip('Segment', c.targetSegment, Icons.group),
              const SizedBox(width: 12),
              _metricChip('Target', '${c.targetCount}', Icons.people),
              if (c.status == 'sent') ...[
                const SizedBox(width: 12),
                _metricChip('Delivered', '${c.deliveredCount}', Icons.check),
                const SizedBox(width: 12),
                _metricChip(
                  'Open Rate',
                  '${openRate.toStringAsFixed(1)}%',
                  Icons.visibility,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricChip(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.white38, size: 14),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: TextStyle(color: Colors.white38, fontSize: 11),
        ),
        Text(
          value,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _emptyState() => Center(
    child: Column(
      children: [
        const SizedBox(height: 80),
        Icon(
          Icons.campaign_outlined,
          size: 64,
          color: Colors.white.withValues(alpha: 0.1),
        ),
        const SizedBox(height: 16),
        Text(
          'No campaigns yet',
          style: GoogleFonts.outfit(fontSize: 18, color: Colors.white54),
        ),
      ],
    ),
  );

  Future<void> _sendCampaign(int id) async {
    try {
      await _repo.sendCampaign(id);
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Campaign sent!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _deleteCampaign(int id) async {
    try {
      await _repo.deleteCampaign(id);
      _loadData();
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
  }

  void _showCreateDialog() {
    final titleCtrl = TextEditingController();
    final msgCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(
          'New Campaign',
          style: GoogleFonts.outfit(color: Colors.white),
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Title',
                  labelStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: msgCtrl,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Message',
                  labelStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _repo.createCampaign({
                'title': titleCtrl.text,
                'message': msgCtrl.text,
              });
              if (ctx.mounted) Navigator.pop(ctx);
              _loadData();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
            ),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
