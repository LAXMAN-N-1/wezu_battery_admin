import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:frontend_admin/core/utils/safe_state.dart';

class AuditStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? trend;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const AuditStatCard({
    super.key,
    required this.title,
    required this.value,
    this.trend,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                if (trend != null)
                  Text(
                    trend!,
                    style: GoogleFonts.inter(
                      color: trend!.startsWith('+') ? Colors.greenAccent : Colors.redAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: GoogleFonts.inter(
                color: Colors.white54,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class JsonDiffViewer extends StatelessWidget {
  final String? oldValue;
  final String? newValue;

  const JsonDiffViewer({super.key, this.oldValue, this.newValue});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('BEFORE', style: GoogleFonts.inter(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              const SizedBox(height: 8),
              _buildCodeBlock(oldValue ?? '{}', Colors.redAccent.withValues(alpha: 0.08), Colors.redAccent),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('AFTER', style: GoogleFonts.inter(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              const SizedBox(height: 8),
              _buildCodeBlock(newValue ?? '{}', Colors.greenAccent.withValues(alpha: 0.08), Colors.greenAccent),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCodeBlock(String content, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.all(12),
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 100),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: text.withValues(alpha: 0.15)),
      ),
      child: SingleChildScrollView(
        child: Text(
          content,
          style: GoogleFonts.robotoMono(fontSize: 11, color: text.withValues(alpha: 0.9), height: 1.5),
        ),
      ),
    );
  }
}

class TerminalConsole extends StatefulWidget {
  final List<String> logs;
  final bool autoScroll;

  const TerminalConsole({super.key, required this.logs, this.autoScroll = true});

  @override
  State<TerminalConsole> createState() => _TerminalConsoleState();
}

class _TerminalConsoleState extends SafeState<TerminalConsole> {
  final ScrollController _scrollController = ScrollController();

  @override
  void didUpdateWidget(TerminalConsole oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.autoScroll && widget.logs.length != oldWidget.logs.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF060F1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: ListView.builder(
        controller: _scrollController,
        itemCount: widget.logs.length,
        itemBuilder: (context, index) {
          final log = widget.logs[index];
          Color textColor = Colors.white70;
          if (log.contains('[CRIT]')) textColor = Colors.redAccent;
          if (log.contains('[WARN]')) textColor = Colors.orangeAccent;
          if (log.contains('[INFO]')) textColor = Colors.blueAccent;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(
              log,
              style: GoogleFonts.sourceCodePro(
                fontSize: 13,
                color: textColor.withValues(alpha: 0.9),
                height: 1.4,
              ),
            ),
          );
        },
      ),
    );
  }
}

class RiskScoreGauge extends StatelessWidget {
  final double score;
  final double size;

  const RiskScoreGauge({super.key, required this.score, this.size = 60});

  @override
  Widget build(BuildContext context) {
    Color color = score < 50 ? Colors.greenAccent : score < 80 ? Colors.orangeAccent : Colors.redAccent;
    
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            value: score / 100,
            strokeWidth: size * 0.1,
            backgroundColor: color.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.8, 0.8)),
        ),
        Text(
          '${score.toInt()}',
          style: GoogleFonts.outfit(
            fontSize: size * 0.35,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

class StickySaveBar extends StatelessWidget {
  final bool isDirty;
  final VoidCallback onSave;
  final VoidCallback onDiscard;
  final bool isLoading;

  const StickySaveBar({
    super.key,
    required this.isDirty,
    required this.onSave,
    required this.onDiscard,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!isDirty) return const SizedBox.shrink();

    return Positioned(
      bottom: 24,
      left: 24,
      right: 24,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.6), blurRadius: 40, offset: const Offset(0, 8)),
          ],
          border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1E293B),
              const Color(0xFF0F172A).withValues(alpha: 0.9),
            ],
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.blueAccent.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: const Icon(Icons.info_outline, color: Colors.blueAccent, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Unsaved Security Policies',
                    style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  Text(
                    'You have modified platform-wide security settings.',
                    style: GoogleFonts.inter(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: onDiscard,
              child: Text('Discard Changes', style: GoogleFonts.inter(color: Colors.white38, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: isLoading ? null : onSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 4,
              ),
              child: isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text('Save & Apply Rules', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ).animate().slideY(begin: 1.5, end: 0, curve: Curves.easeOutCubic, duration: 400.ms),
    );
  }
}
