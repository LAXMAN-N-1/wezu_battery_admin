import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class WezuLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final Color? color;

  const WezuLogo({
    super.key,
    this.size = 100,
    this.showText = true,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Outer glow
            Container(
                  width: size * 0.8,
                  height: size * 0.8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (color ?? const Color(0xFF3B82F6)).withValues(alpha: 
                          0.2,
                        ),
                        blurRadius: size * 0.5,
                        spreadRadius: size * 0.1,
                      ),
                    ],
                  ),
                )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(
                  begin: const Offset(0.8, 0.8),
                  end: const Offset(1.2, 1.2),
                  duration: 2.seconds,
                  curve: Curves.easeInOut,
                ),

            // Modern Lightning Bolt Icon (Vector-like)
            Icon(
                  Icons.bolt_rounded,
                  size: size,
                  color: color ?? const Color(0xFF3B82F6),
                )
                .animate(onPlay: (c) => c.repeat())
                .shimmer(
                  duration: 2.seconds,
                  color: Colors.white.withValues(alpha: 0.5),
                )
                .custom(
                  duration: 3.seconds,
                  curve: Curves.easeInOut,
                  builder: (context, value, child) => Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: (color ?? const Color(0xFF3B82F6)).withValues(alpha: 
                            0.5 * value,
                          ),
                          blurRadius: 20.0 * value,
                          spreadRadius: 2.0 * value,
                        ),
                      ],
                    ),
                    child: child,
                  ),
                ),
          ],
        ),
        if (showText) ...[
          const SizedBox(height: 16),
          Text(
            'WEZU ENERGY',
            style: GoogleFonts.outfit(
              fontSize: size * 0.25,
              fontWeight: FontWeight.w900,
              letterSpacing: 4,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: (color ?? const Color(0xFF3B82F6)).withValues(alpha: 0.5),
                  blurRadius: 10,
                ),
              ],
            ),
          ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.2),
        ],
      ],
    );
  }
}

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Duration delay;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.delay = Duration.zero,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: 200,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: const Color(0xFF3B82F6), size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          value,
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          label,
                          style: GoogleFonts.inter(
                            color: Colors.white38,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
        .animate(delay: delay)
        .fadeIn(duration: 800.ms)
        .slideX(begin: -0.2)
        .then()
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .moveY(begin: -5, end: 5, duration: 3.seconds, curve: Curves.easeInOut);
  }
}

class AdminTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final VoidCallback? onToggleObscure;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final TextInputAction? textInputAction;

  const AdminTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.onToggleObscure,
    this.onChanged,
    this.keyboardType,
    this.autofillHints,
    this.textInputAction,
  });

  @override
  State<AdminTextField> createState() => _AdminTextFieldState();
}

class _AdminTextFieldState extends State<AdminTextField> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: GoogleFonts.inter(
            color: Colors.white54,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Focus(
          onFocusChange: (hasFocus) => setState(() => _isFocused = hasFocus),
          child: AnimatedContainer(
            duration: 300.ms,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: _isFocused
                  ? [
                      BoxShadow(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ]
                  : [],
            ),
            child: TextField(
              controller: widget.controller,
              obscureText: widget.obscureText,
              onChanged: widget.onChanged,
              keyboardType: widget.keyboardType,
              autofillHints: widget.autofillHints,
              textInputAction: widget.textInputAction,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2)),
                prefixIcon: Icon(
                  widget.icon,
                  color: _isFocused ? const Color(0xFF3B82F6) : Colors.white24,
                  size: 20,
                ),
                suffixIcon: widget.onToggleObscure != null
                    ? IconButton(
                        icon: Icon(
                          widget.obscureText
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: Colors.white24,
                          size: 20,
                        ),
                        onPressed: widget.onToggleObscure,
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFF1F2937),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF3B82F6),
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class AdminButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  const AdminButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.white,
                ),
              ),
      ),
    ).animate().shimmer(
      duration: 2.seconds,
      color: Colors.white.withValues(alpha: 0.1),
      delay: 1.seconds,
    );
  }
}

// ============================================================================
// NEW PREMIUN COMPONENTS FOR PHASE 2 OVERHAUL
// ============================================================================

/// A premium card with subtle glassmorphism and borders.
class AdvancedCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double? width;
  final double? height;

  const AdvancedCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Animated, glowing status badge
class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final lowerStatus = status.toLowerCase();
    Color color;
    Color bgColor;

    if (lowerStatus == 'active' ||
        lowerStatus == 'completed' ||
        lowerStatus == 'resolved') {
      color = const Color(0xFF22C55E);
    } else if (lowerStatus == 'maintenance' ||
        lowerStatus == 'pending' ||
        lowerStatus == 'in-progress') {
      color = const Color(0xFFF59E0B);
    } else if (lowerStatus == 'inactive' ||
        lowerStatus == 'suspended' ||
        lowerStatus == 'failed') {
      color = const Color(0xFFEF4444);
    } else {
      color = const Color(0xFF3B82F6); // Default blue
    }

    bgColor = color.withValues(alpha: 0.15);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.5),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .fade(duration: 1.seconds, begin: 0.5, end: 1.0),
          const SizedBox(width: 6),
          Text(
            status.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Premium top header for individual pages/views
class PageHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? actionButton;
  final Widget? searchField;

  const PageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.actionButton,
    this.searchField,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1),
                const SizedBox(height: 4),
                Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white54,
                      ),
                      overflow: TextOverflow.ellipsis,
                    )
                    .animate()
                    .fadeIn(duration: 400.ms, delay: 100.ms)
                    .slideX(begin: -0.1),
              ],
            ),
          ),
          const SizedBox(width: 16),
          if (searchField != null) ...[
            SizedBox(width: 250, child: searchField),
            const SizedBox(width: 16),
          ],
          if (actionButton != null)
            actionButton!
                .animate()
                .fadeIn(duration: 400.ms, delay: 200.ms)
                .scale(begin: const Offset(0.9, 0.9)),
        ],
      ),
    );
  }
}

/// A unified, highly styled data table with hover row highlights.
class AdvancedTable extends StatelessWidget {
  final List<String> columns;
  final List<List<Widget>> rows;
  final Function(int)? onRowTap;

  const AdvancedTable({
    super.key,
    required this.columns,
    required this.rows,
    this.onRowTap,
  });

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.inbox_outlined,
                size: 48,
                color: Colors.white.withValues(alpha: 0.2),
              ),
              const SizedBox(height: 16),
              Text(
                'No data available',
                style: GoogleFonts.inter(color: Colors.white54, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final double effectiveMaxWidth = constraints.maxWidth == double.infinity
            ? MediaQuery.of(context).size.width
            : constraints.maxWidth;
        final totalMinContentWidth = (columns.length * 120.0) + 32.0;
        final actualWidth = effectiveMaxWidth > totalMinContentWidth
            ? effectiveMaxWidth
            : totalMinContentWidth;
        final colWidth = actualWidth / columns.length;

        final header = Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: columns.map((col) {
              return SizedBox(
                width:
                    colWidth - (32 / columns.length), // Adjusting for padding
                child: Text(
                  col.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.white38,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
          ),
        );

        final rowsList = Column(
          children: rows.asMap().entries.map((entry) {
            final idx = entry.key;
            final rowWidgets = entry.value;
            final rowContent = Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                border: idx < rows.length - 1
                    ? Border(
                        bottom: BorderSide(
                          color: Colors.white.withValues(alpha: 0.04),
                        ),
                      )
                    : null,
              ),
              child: Row(
                children: rowWidgets.map((w) {
                  return SizedBox(
                    width: colWidth - (32 / columns.length),
                    child: w,
                  );
                }).toList(),
              ),
            );

            final widget = onRowTap != null
                ? InkWell(
                    onTap: () => onRowTap!(idx),
                    hoverColor: Colors.white.withValues(alpha: 0.03),
                    child: rowContent,
                  )
                : rowContent;

            return widget
                .animate()
                .fadeIn(duration: 300.ms, delay: (idx * 50).ms)
                .slideX(begin: 0.05);
          }).toList(),
        );

        final tableContent = Column(
          children: [
            header,
            const SizedBox(height: 8),
            if (constraints.maxHeight == double.infinity)
              rowsList
            else
              Expanded(child: SingleChildScrollView(child: rowsList)),
          ],
        );

        if (actualWidth > effectiveMaxWidth) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(width: actualWidth, child: tableContent),
          );
        }

        return tableContent;
      },
    );
  }
}

