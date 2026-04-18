import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/widgets/admin_ui_components.dart';
import '../../../core/theme/app_themes.dart';
import '../data/models/settings_models.dart';
import '../providers/api_keys_provider.dart';
import '../providers/webhooks_provider.dart';
import '../widgets/generate_key_dialog.dart';
import '../widgets/add_webhook_dialog.dart';

class ApiKeysView extends ConsumerStatefulWidget {
  const ApiKeysView({super.key});

  @override
  ConsumerState<ApiKeysView> createState() => _ApiKeysViewState();
}

class _ApiKeysViewState extends ConsumerState<ApiKeysView> {
  String _activeCategory = 'All';
  String _activeSubTab = 'API Keys';
  
  final List<String> _categories = [
    'All', 'Payments', 'SMS / Messaging', 'Email Service',
    'Storage', 'Analytics', 'Webhooks', 'Custom'
  ];

  final List<String> _subTabs = ['API Keys', 'Webhooks'];

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final keysAsync = ref.watch(apiKeysProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16 : 32),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: constraints.maxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PageHeader(
                  title: _activeSubTab == 'API Keys' ? 'API Keys & Integrations' : _activeSubTab,
                  subtitle: _activeSubTab == 'API Keys' 
                    ? 'Manage credentials for third-party services.'
                    : 'Configure and test real-time notification endpoints.',
                  showRealData: true,
                  actionButton: AdminButton(
                    label: _activeSubTab == 'API Keys' ? 'Generate New Key' : 'Add Webhook',
                    onPressed: _activeSubTab == 'API Keys' ? _showGenerateDialog : _showAddWebhookDialog,
                  ),
                ),
                const SizedBox(height: 24),

                // Sub-tab switcher
                _buildSubTabs(colors),
                const SizedBox(height: 32),

                if (_activeSubTab == 'API Keys') ...[
                  // Warning banner
                  _buildWarningBanner(colors),
                  const SizedBox(height: 24),

                  // Category tabs
                  _buildCategoryTabs(colors),
                  const SizedBox(height: 24),

                  // Keys table
                  keysAsync.when(
                    data: (keys) {
                      final filtered = _activeCategory == 'All'
                          ? keys
                          : keys.where((k) => k.category == _activeCategory).toList();
                      return _buildKeysTable(filtered, colors);
                    },
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 80),
                        child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
                      ),
                    ),
                    error: (err, _) => Center(
                      child: Text('Error: $err', style: const TextStyle(color: Colors.red)),
                    ),
                  ),
                ] else ...[
                  _buildWebhooksView(colors),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWarningBanner(AppColorsExtension colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_outline, color: const Color(0xFFF59E0B)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'API keys shown below are partially masked. The full key was only visible at creation time. If lost, generate a new key.',
              style: GoogleFonts.inter(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.9),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs(AppColorsExtension colors) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _categories.map((category) {
          final isActive = _activeCategory == category;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: GestureDetector(
              onTap: () => setState(() => _activeCategory = category),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isActive ? colors.accent.withValues(alpha: 0.15) : colors.border.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isActive ? colors.accent.withValues(alpha: 0.5) : colors.border.withValues(alpha: 0.1),
                  ),
                ),
                child: Text(
                  category,
                  style: GoogleFonts.inter(
                    color: isActive ? colors.accent : colors.textSecondary,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildKeysTable(List<ApiKeyItem> keys, AppColorsExtension colors) {
    if (keys.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Text(
            'No API keys found in this category',
            style: GoogleFonts.inter(color: Colors.white24),
          ),
        ),
      );
    }

    return AdvancedTable(
      columns: const [
        'Service', 'Key Label', 'API Key Value', 'Environment', 
        'Last Used', 'Expires', 'Status', 'Actions'
      ],
      columnFlex: const [2, 2, 3, 1, 1, 1, 2, 1],
      columnAlignments: const [
        Alignment.centerLeft, Alignment.centerLeft, Alignment.centerLeft,
        Alignment.center, Alignment.center, Alignment.center,
        Alignment.center, Alignment.center
      ],
      rows: keys.map((key) {
        final List<Widget> rowContent = [
          _buildServiceCell(key),
          _buildTextCell(key.keyName, bold: true),
          _buildMaskedKeyCell(key, colors),
          _buildEnvironmentBadge(key.environment),
          _buildTimeCell(key.lastUsedAt),
          _buildExpiresCell(key.expiresAt),
          _buildStatusToggle(key, colors),
          _buildActionsCell(key, colors),
        ];

        if (!key.isActive) {
          return rowContent.map((w) => Opacity(opacity: 0.4, child: w)).toList();
        }
        return rowContent;
      }).toList(),
    );
  }

  Widget _buildServiceCell(ApiKeyItem key) {
    final (icon, color) = _getServiceIcon(key.serviceName);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
              ),
            ],
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            key.serviceName,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildTextCell(String text, {bool bold = false}) {
    return Text(
      text,
      style: GoogleFonts.inter(
        color: Colors.white70,
        fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
        fontSize: 13,
      ),
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildMaskedKeyCell(ApiKeyItem key, AppColorsExtension colors) {
    final isRevoked = !key.isActive;
    return Row(
      children: [
        Expanded(
          child: Text(
            isRevoked ? '••••••••••••••••' : key.keyValueMasked,
            style: GoogleFonts.robotoMono(
              color: isRevoked ? Colors.white38 : Colors.white70,
              fontSize: 13,
              letterSpacing: 1.0,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (!isRevoked)
          SecureCopyButton(apiKeyId: key.id),
      ],
    );
  }

  Widget _buildEnvironmentBadge(String env) {
    final lower = env.toLowerCase();
    Color color;
    if (lower == 'production') {
      color = const Color(0xFF22C55E); // Green
    } else if (lower == 'sandbox') {
      color = const Color(0xFFF59E0B); // Amber
    } else {
      color = const Color(0xFF64748B); // Slate/Grey for Development
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        env.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTimeCell(String? timestamp) {
    if (timestamp == null || timestamp.isEmpty) {
      return Text('Never', style: GoogleFonts.inter(color: Colors.white38, fontSize: 13));
    }
    
    // Convert to relative time string
    try {
      final dt = DateTime.parse(timestamp);
      final diff = DateTime.now().difference(dt);
      String relative = '';
      if (diff.inDays > 0) {
        relative = '${diff.inDays}d ago';
      } else if (diff.inHours > 0) {
        relative = '${diff.inHours}h ago';
      } else {
        relative = '${diff.inMinutes}m ago';
      }

      return Text(relative, style: GoogleFonts.inter(color: Colors.white70, fontSize: 13));
    } catch (_) {
      return Text(timestamp, style: GoogleFonts.inter(color: Colors.white70, fontSize: 13), overflow: TextOverflow.ellipsis);
    }
  }

  Widget _buildExpiresCell(String? expiresAt) {
    if (expiresAt == null || expiresAt.isEmpty) {
      return Text('Never', style: GoogleFonts.inter(color: Colors.white38, fontSize: 13));
    }

    try {
      final dt = DateTime.parse(expiresAt);
      final diff = dt.difference(DateTime.now());
      final isNearExpiry = diff.inDays <= 7 && diff.inDays >= 0;
      final isExpired = diff.inDays < 0;

      final format = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      
      Color color = Colors.white70;
      if (isExpired) {
        color = Colors.red;
      } else if (isNearExpiry) {
        color = const Color(0xFFF59E0B);
      }

      return Text(format, style: GoogleFonts.inter(color: color, fontSize: 13, fontWeight: (isExpired || isNearExpiry) ? FontWeight.bold : FontWeight.normal));
    } catch (_) {
      return Text(expiresAt, style: GoogleFonts.inter(color: Colors.white70, fontSize: 13));
    }
  }

  Widget _buildStatusToggle(ApiKeyItem key, AppColorsExtension colors) {
    final isActive = key.isActive;
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 4,
      children: [
        Switch(
          value: isActive,
          thumbColor: WidgetStateProperty.all(Colors.white),
          activeTrackColor: const Color(0xFF22C55E),
          inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
          inactiveThumbColor: Colors.white38,
          onChanged: isActive ? null : (_) {},
        ),
        if (!isActive)
          StatusBadge(status: 'REVOKED'),
      ],
    );
  }

  Widget _buildActionsCell(ApiKeyItem key, AppColorsExtension colors) {
    final isRevoked = !key.isActive;
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_horiz, color: Colors.white54, size: 20),
      color: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      elevation: 8,
      onSelected: (value) {
        if (value == 'rotate') _confirmRotate(key);
        if (value == 'revoke') _confirmRevoke(key);
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'rotate',
          enabled: !isRevoked,
          child: Row(
            children: [
              Icon(Icons.autorenew, color: isRevoked ? Colors.white24 : const Color(0xFFF59E0B), size: 18),
              const SizedBox(width: 12),
              Text('Rotate Key', style: GoogleFonts.inter(color: isRevoked ? Colors.white24 : Colors.white70, fontSize: 13)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'revoke',
          enabled: !isRevoked,
          child: Row(
            children: [
              Icon(Icons.block, color: isRevoked ? Colors.white24 : Colors.red, size: 18),
              const SizedBox(width: 12),
              Text('Revoke Key', style: GoogleFonts.inter(color: isRevoked ? Colors.white24 : Colors.red, fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }

  void _confirmRotate(ApiKeyItem key) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFF59E0B), width: 1.5),
          ),
        title: Row(
          children: [
             Icon(Icons.warning_amber_rounded, color: const Color(0xFFF59E0B)),
             const SizedBox(width: 10),
             Text('Rotate Key', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
          ]
        ),
        content: Text(
          'Rotating this key will immediately invalidate the current key. Any service using the old key will stop working until updated. Continue?',
          style: GoogleFonts.inter(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Discard', style: GoogleFonts.inter(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B)),
            onPressed: () async {
              Navigator.pop(ctx);
              final newKey = await ref.read(apiKeysProvider.notifier).rotateApiKey(key.id);
              if (mounted && newKey != null) {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => GenerateKeyDialog(
                    initialKey: newKey,
                    initialService: key.serviceName,
                  ),
                );
                _showToast('Key rotated successfully', true);
              }
            },
            child: Text('Rotate Key', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          ],
        );
      },
    );
  }

  void _confirmRevoke(ApiKeyItem key) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.red, width: 1.5),
        ),
        title: Row(
          children: [
             Icon(Icons.dangerous_outlined, color: Colors.red),
             const SizedBox(width: 10),
             Text('Revoke Key', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
          ]
        ),
        content: Text(
          'Revoking this key will permanently disable it. This cannot be undone. Services using this key will lose access immediately.',
          style: GoogleFonts.inter(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Discard', style: GoogleFonts.inter(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(apiKeysProvider.notifier).deleteApiKey(key.id);
              if (mounted) {
                _showToast('Key revoked', true);
              }
            },
            child: Text('Revoke Key', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
  Widget _buildSubTabs(AppColorsExtension colors) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.border.withValues(alpha: 0.1))),
      ),
      child: Row(
        children: _subTabs.map((tab) {
          final isActive = _activeSubTab == tab;
          return GestureDetector(
            onTap: () => setState(() => _activeSubTab = tab),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 32),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isActive ? colors.accent : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Text(
                tab,
                style: GoogleFonts.inter(
                  color: isActive ? colors.accent : colors.textSecondary,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 15,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildWebhooksView(AppColorsExtension colors) {
    final webhooksAsync = ref.watch(webhooksProvider);

    return webhooksAsync.when(
      data: (webhooks) => _buildWebhooksTable(webhooks, colors),
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 80),
          child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
        ),
      ),
      error: (err, _) => Center(
        child: Text('Error: $err', style: const TextStyle(color: Colors.red)),
      ),
    );
  }

  Widget _buildWebhooksTable(List<WebhookItem> webhooks, AppColorsExtension colors) {
    return AdvancedTable(
      columns: const ['Endpoint URL', 'Events', 'Status', 'Last Ping', 'Actions'],
      columnFlex: const [4, 3, 1, 1, 1],
      columnAlignments: const [
        Alignment.centerLeft, Alignment.centerLeft, 
        Alignment.center, Alignment.center, Alignment.center
      ],
      rows: webhooks.map((w) => [
        _buildUrlCell(w, colors),
        _buildEventsCell(w.events),
        _buildWebhookStatusToggle(w, colors),
        _buildTimeCell(w.lastPingAt),
        _buildWebhookActions(w, colors),
      ]).toList(),
    );
  }

  Widget _buildUrlCell(WebhookItem w, AppColorsExtension colors) {
    return Row(
      children: [
        Expanded(
          child: Text(
            w.url,
            style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (w.lastResponseCode != null) ...[
          const SizedBox(width: 8),
          _buildResponseCodeBadge(w.lastResponseCode!),
        ],
      ],
    );
  }

  Widget _buildResponseCodeBadge(int code) {
    if (code == -1) {
      return const SizedBox(
        width: 14,
        height: 14,
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white38),
      );
    }

    final isSuccess = code >= 200 && code < 300;
    final color = isSuccess ? const Color(0xFF22C55E) : Colors.red;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        code.toString(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    ).animate().fadeIn().scale();
  }

  Widget _buildEventsCell(List<String> events) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: (events.take(2).map<Widget>((e) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          e,
          style: GoogleFonts.inter(color: Colors.white54, fontSize: 10),
        ),
      )).toList()..addAll(
        events.length > 2 
          ? [Text(' +${events.length - 2}', style: const TextStyle(color: Colors.white24, fontSize: 10))]
          : []
      )),
    );
  }

  Widget _buildWebhookStatusToggle(WebhookItem w, AppColorsExtension colors) {
    return Switch(
      value: w.isActive,
      thumbColor: WidgetStateProperty.all(Colors.white),
      activeTrackColor: const Color(0xFF22C55E),
      onChanged: (_) {},
    );
  }

  Widget _buildWebhookActions(WebhookItem w, AppColorsExtension colors) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_horiz, color: Colors.white54, size: 20),
      color: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      elevation: 8,
      onSelected: (value) {
        switch (value) {
          case 'ping':
            ref.read(webhooksProvider.notifier).testPing(w.id);
            break;
          case 'edit':
            // Logic for edit can be added here
            break;
          case 'delete':
            ref.read(webhooksProvider.notifier).deleteWebhook(w.id);
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'ping',
          child: Row(
            children: [
              const Icon(Icons.sensors, color: Color(0xFF3B82F6), size: 18),
              const SizedBox(width: 12),
              Text('Test Connectivity', style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              const Icon(Icons.edit_outlined, color: Colors.white54, size: 18),
              const SizedBox(width: 12),
              Text('Edit Endpoint', style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
              const SizedBox(width: 12),
              Text('Delete Endpoint', style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }

  void _showAddWebhookDialog() {
    showDialog(
      context: context,
      builder: (ctx) => const AddWebhookDialog(),
    );
  }

  void _showGenerateDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const GenerateKeyDialog(),
    );
  }

  void _showToast(String message, bool isSuccess) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isSuccess ? Icons.check_circle : Icons.error, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text(message, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500)),
          ],
        ),
        backgroundColor: isSuccess ? const Color(0xFF22C55E) : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.only(bottom: 24, right: 24, left: 24),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  (IconData, Color) _getServiceIcon(String service) {
    final s = service.toLowerCase();
    if (s.contains('stripe')) return (Icons.payment, const Color(0xFF6366F1));
    if (s.contains('google')) return (Icons.map, const Color(0xFF34A853));
    if (s.contains('sendgrid')) return (Icons.email, const Color(0xFF0EA5E9));
    if (s.contains('twilio')) return (Icons.sms, const Color(0xFFEF4444));
    if (s.contains('aws')) return (Icons.cloud, const Color(0xFFF59E0B));
    return (Icons.api, const Color(0xFFA855F7));
  }
}

class SecureCopyButton extends ConsumerStatefulWidget {
  final int apiKeyId;
  const SecureCopyButton({super.key, required this.apiKeyId});

  @override
  ConsumerState<SecureCopyButton> createState() => _SecureCopyButtonState();
}

class _SecureCopyButtonState extends ConsumerState<SecureCopyButton> {
  bool _isRetrieving = false;

  Future<void> _handleCopy() async {
    setState(() => _isRetrieving = true);
    try {
      final plaintext = await ref.read(apiKeysProvider.notifier).getPlaintextApiKey(widget.apiKeyId);
      await Clipboard.setData(ClipboardData(text: plaintext));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text('API key copied to clipboard', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500)),
              ],
            ),
            backgroundColor: const Color(0xFF22C55E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(24),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isRetrieving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isRetrieving) {
      return const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF3B82F6)),
      ).animate().fadeIn();
    }

    return IconButton(
      icon: const Icon(Icons.copy, size: 16, color: Colors.white54),
      onPressed: _handleCopy,
      tooltip: 'Securely retrieve and copy full key',
      constraints: const BoxConstraints(),
      padding: const EdgeInsets.all(4),
    );
  }
}

class TestPingButton extends ConsumerStatefulWidget {
  final int webhookId;
  const TestPingButton({super.key, required this.webhookId});

  @override
  ConsumerState<TestPingButton> createState() => _TestPingButtonState();
}

class _TestPingButtonState extends ConsumerState<TestPingButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final webhooks = ref.watch(webhooksProvider).valueOrNull ?? [];
    final webhook = webhooks.firstWhere((w) => w.id == widget.webhookId, orElse: () => WebhookItem(id: 0, url: '', events: [], isActive: false));
    final isLoading = webhook.lastResponseCode == -1;

    if (isLoading && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!isLoading && _controller.isAnimating) {
      _controller.stop();
    }

    return IconButton(
      icon: Stack(
        alignment: Alignment.center,
        children: [
          const Icon(Icons.sensors, color: Color(0xFF3B82F6), size: 18),
          if (isLoading)
            const Icon(Icons.sensors, color: Colors.white30, size: 24)
                .animate(onPlay: (c) => c.repeat())
                .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.5, 1.5))
                .fadeOut(),
        ],
      ),
      onPressed: isLoading ? null : () => ref.read(webhooksProvider.notifier).testPing(widget.webhookId),
      tooltip: 'Test Connectivity',
      padding: const EdgeInsets.all(4),
      constraints: const BoxConstraints(),
    );
  }
}
