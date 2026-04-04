import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/models/notification_models.dart';
import '../data/repositories/notification_repository.dart';

class AutomatedTriggersView extends StatefulWidget {
  const AutomatedTriggersView({super.key});
  @override
  State<AutomatedTriggersView> createState() => _AutomatedTriggersViewState();
}

class _AutomatedTriggersViewState extends State<AutomatedTriggersView> {
  final NotificationRepository _repo = NotificationRepository();
  List<AutomatedTrigger> _triggers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _triggers = await _repo.getTriggers();
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
          Text(
            'Automated Triggers',
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Configure behavioral triggers for automated notifications',
            style: GoogleFonts.inter(color: Colors.white54, fontSize: 14),
          ),
          const SizedBox(height: 24),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(children: _triggers.map(_buildTriggerCard).toList()),
        ],
      ),
    );
  }

  Widget _buildTriggerCard(AutomatedTrigger t) {
    final eventIcon = _eventIcon(t.eventType);
    final channelColor = t.channel == 'push'
        ? Colors.blue
        : t.channel == 'sms'
        ? Colors.green
        : Colors.orange;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: t.isActive
              ? Colors.green.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: eventIcon.$2.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(eventIcon.$1, color: eventIcon.$2, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.name,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (t.description != null)
                      Text(
                        t.description!,
                        style: GoogleFonts.inter(
                          color: Colors.white38,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              Switch(
                value: t.isActive,
                activeThumbColor: Colors.green,
                onChanged: (val) async {
                  await _repo.updateTrigger(t.id, {'is_active': val});
                  _loadData();
                },
              ),
              IconButton(
                icon: const Icon(
                  Icons.edit_outlined,
                  color: Colors.blue,
                  size: 18,
                ),
                onPressed: () => _showEditDialog(t),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              t.templateMessage,
              style: GoogleFonts.inter(
                color: Colors.white70,
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 16,
            children: [
              _infoChip(
                Icons.flash_on,
                'Event',
                t.eventType.replaceAll('_', ' '),
                eventIcon.$2,
              ),
              _infoChip(
                Icons.notifications_active,
                'Channel',
                t.channel.toUpperCase(),
                channelColor,
              ),
              _infoChip(
                Icons.timer,
                'Delay',
                t.delayMinutes == 0 ? 'Instant' : '${t.delayMinutes} min',
                Colors.white54,
              ),
              _infoChip(
                Icons.numbers,
                'Triggered',
                '${t.triggerCount}x',
                Colors.white54,
              ),
              if (t.lastTriggeredAt != null)
                _infoChip(
                  Icons.access_time,
                  'Last',
                  _formatTs(t.lastTriggeredAt!),
                  Colors.white38,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: GoogleFonts.inter(color: Colors.white38, fontSize: 11),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _showEditDialog(AutomatedTrigger t) {
    final nameCtrl = TextEditingController(text: t.name);
    final descCtrl = TextEditingController(text: t.description);
    final msgCtrl = TextEditingController(text: t.templateMessage);
    final delayCtrl = TextEditingController(text: t.delayMinutes.toString());
    bool isActive = t.isActive;
    String channel = t.channel;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: Text(
            'Edit Trigger: ${t.eventType.toUpperCase()}',
            style: GoogleFonts.outfit(color: Colors.white),
          ),
          content: SizedBox(
            width: 550,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDeco('Trigger Name'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDeco('Description/Notes'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: msgCtrl,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 4,
                  decoration: _inputDeco(
                    'Message Template (use {{user.name}}, {{battery.id}})',
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: delayCtrl,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDeco('Delay (mins, 0=instant)'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: channel,
                        dropdownColor: const Color(0xFF1E293B),
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDeco('Delivery Channel').copyWith(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: ['push', 'sms', 'email']
                            .map(
                              (s) => DropdownMenuItem(
                                value: s,
                                child: Text(s.toUpperCase()),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setModalState(() => channel = v);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: SwitchListTile(
                          title: Text(
                            'Active',
                            style: GoogleFonts.inter(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                          value: isActive,
                          activeThumbColor: Colors.green,
                          inactiveTrackColor: Colors.white12,
                          onChanged: (v) => setModalState(() => isActive = v),
                        ),
                      ),
                    ),
                  ],
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
                await _repo.updateTrigger(t.id, {
                  'name': nameCtrl.text,
                  'description': descCtrl.text,
                  'template_message': msgCtrl.text,
                  'delay_minutes': int.tryParse(delayCtrl.text) ?? 0,
                  'channel': channel,
                  'is_active': isActive,
                });
                if (ctx.mounted) Navigator.pop(ctx);
                _loadData();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
              ),
              child: const Text('Save Configure'),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String label) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: Colors.white38),
    filled: true,
    fillColor: Colors.white.withValues(alpha: 0.05),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide.none,
    ),
  );

  (IconData, Color) _eventIcon(String type) {
    switch (type) {
      case 'welcome':
        return (Icons.celebration, Colors.purple);
      case 'rental_reminder':
        return (Icons.alarm, Colors.amber);
      case 'payment_due':
        return (Icons.payment, Colors.red);
      case 'low_battery':
        return (Icons.battery_alert, Colors.orange);
      case 'inactivity':
        return (Icons.hourglass_empty, Colors.grey);
      case 'swap_complete':
        return (Icons.swap_horiz, Colors.teal);
      default:
        return (Icons.notifications, Colors.blue);
    }
  }

  String _formatTs(String ts) {
    try {
      final dt = DateTime.parse(ts);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return ts;
    }
  }
}
