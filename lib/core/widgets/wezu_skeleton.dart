import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// A single shimmer block element using flutter_animate (already in pubspec.lock).
class WezuSkeleton extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const WezuSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(
          duration: 1200.ms,
          color: const Color(0xFF334155),
        );
  }
}

/// A table-shaped skeleton loader that mimics data rows during loading.
class WezuSkeletonTable extends StatelessWidget {
  final int rows;
  final int columns;
  final double rowHeight;

  const WezuSkeletonTable({
    super.key,
    this.rows = 8,
    this.columns = 6,
    this.rowHeight = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(rows, (rowIndex) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            border: rowIndex < rows - 1
                ? const Border(
                    bottom: BorderSide(
                      color: Color(0x0AFFFFFF), // ~4% white
                    ),
                  )
                : null,
          ),
          child: Row(
            children: List.generate(columns, (colIndex) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                      right: colIndex < columns - 1 ? 16.0 : 0),
                  child: WezuSkeleton(
                    height: rowHeight,
                    width: double.infinity,
                    borderRadius: 4,
                  ),
                ),
              );
            }),
          ),
        );
      }),
    );
  }
}
