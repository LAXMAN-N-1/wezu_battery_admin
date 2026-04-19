
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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
            // Outer glow (static — no repeating animation)
            Container(
              width: size * 0.8,
              height: size * 0.8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (color ?? const Color(0xFF3B82F6)).withValues(alpha: 0.2),
                    blurRadius: size * 0.5,
                    spreadRadius: size * 0.1,
                  ),
                ],
              ),
            ).animate().scale(
              begin: const Offset(0.8, 0.8),
              end: const Offset(1.0, 1.0),
              duration: 1.seconds,
              curve: Curves.easeOut,
            ),

            // Lightning Bolt Icon (one-shot shimmer)
            Icon(
              Icons.bolt_rounded,
              size: size,
              color: color ?? const Color(0xFF3B82F6),
            ).animate().shimmer(
              duration: 2.seconds,
              color: Colors.white.withValues(alpha: 0.5),
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
    return Container(
      width: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
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
    )
    .animate(delay: delay)
    .fadeIn(duration: 800.ms)
    .slideX(begin: -0.2);
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
  final int maxLines;

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
    this.maxLines = 1,
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
  final double? width;
  final double? height;

  const AdminButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? double.infinity,
      height: height ?? 52,
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
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(height != null && height! < 40 ? 8 : 12),
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
                  fontSize: height != null && height! < 40 ? 12 : 15,
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
              ),
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

/// A premium indicator for real-time backend data.
class RealDataBadge extends StatelessWidget {
  const RealDataBadge({super.key});

  @override
  Widget build(BuildContext context) {
    // Hidden on Android as requested
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return const SizedBox.shrink();
    }

    const green = Color(0xFF22C55E);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: green.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: green,
                  boxShadow: [
                    BoxShadow(
                      color: green,
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
          const SizedBox(width: 6),
          Text(
            'REAL DATA',
            style: GoogleFonts.inter(
              fontSize: 9,
              color: green,
              fontWeight: FontWeight.w800,
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
  final bool showRealData;

  const PageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.actionButton,
    this.searchField,
    this.showRealData = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        if (isMobile) {
          return Container(
            margin: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (showRealData) ...[
                      const SizedBox(width: 8),
                      const RealDataBadge(),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.white54,
                  ),
                ),
                if (searchField != null || actionButton != null) ...[
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (searchField != null) 
                        Expanded(child: searchField!),
                      if (searchField != null && actionButton != null)
                        const SizedBox(width: 12),
                      if (actionButton != null)
                        actionButton!,
                    ],
                  ),
                ],
              ],
            ),
          );
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.outfit(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (showRealData) ...[
                          const SizedBox(width: 12),
                          const RealDataBadge(),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white54,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              if (searchField != null) ...[
                SizedBox(width: 250, child: searchField),
                const SizedBox(width: 16),
              ],
              if (actionButton != null) actionButton!,
            ],
          ),
        );
      },
    );
  }
}

/// A unified, highly styled data table with hover row highlights.
class AdvancedTable extends StatelessWidget {
  final List<String> columns;
  final List<List<Widget>> rows;
  final Function(int)? onRowTap;
  final String? sortColumn;
  final bool sortAscending;
  final Function(String)? onSort;
  final List<int>? columnFlex; 
  final List<Alignment>? columnAlignments;
  const AdvancedTable({
    super.key,
    required this.columns,
    required this.rows,
    this.onRowTap,
    this.sortColumn,
    this.sortAscending = true,
    this.onSort,
    this.columnFlex,
    this.columnAlignments,
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
        final totalFlex = columnFlex?.fold<int>(0, (p, c) => p + c) ?? columns.length;

        final header = Container(
          width: actualWidth,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: columns.asMap().entries.map((entry) {
              final idx = entry.key;
              final col = entry.value;
              final isSorted = sortColumn == col;
              final flex = columnFlex != null && idx < columnFlex!.length ? columnFlex![idx] : 1;
              final alignment = columnAlignments != null && idx < columnAlignments!.length 
                  ? columnAlignments![idx] 
                  : Alignment.centerLeft;
              
              return Expanded(
                flex: flex,
                child: MouseRegion(
                  cursor: onSort != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
                  child: GestureDetector(
                    onTap: () => onSort?.call(col),
                    child: Align(
                      alignment: alignment,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              col.toUpperCase(),
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: isSorted ? Colors.white : Colors.white38,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isSorted) ...[
                            const SizedBox(width: 4),
                            Icon(
                              sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                              size: 12,
                              color: const Color(0xFF3B82F6),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
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
              width: actualWidth,
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
                mainAxisSize: MainAxisSize.max,
                children: rowWidgets.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final w = entry.value;
                  final flex = columnFlex != null && idx < columnFlex!.length ? columnFlex![idx] : 1;
                  final alignment = columnAlignments != null && idx < columnAlignments!.length 
                      ? columnAlignments![idx] 
                      : Alignment.centerLeft;
                  
                  return Expanded(
                    flex: flex,
                    child: Align(
                      alignment: alignment,
                      child: w,
                    ),
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
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            header,
            const SizedBox(height: 8),
            rowsList,
          ],
        );

        if (actualWidth > effectiveMaxWidth || constraints.maxWidth == double.infinity) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: tableContent,
          );
        }

        return tableContent;
      },
    );
  }
}

