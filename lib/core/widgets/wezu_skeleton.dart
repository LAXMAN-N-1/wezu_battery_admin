import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

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
    return Shimmer.fromColors(
      baseColor: const Color(0xFF1E293B), // Matches Dark Theme Backgrounds
      highlightColor: const Color(0xFF334155), // Lighter Slate for the sweeper
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

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
                ? Border(
                    bottom: BorderSide(
                      color: Colors.white.withValues(alpha: 0.04), // Replicates AdvancedTable divider
                    ),
                  )
                : null,
          ),
          child: Row(
            children: List.generate(columns, (colIndex) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: colIndex < columns - 1 ? 16.0 : 0),
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
