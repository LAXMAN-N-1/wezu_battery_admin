import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../stations/data/providers/station_performance_provider.dart';

class StationRankingList extends ConsumerWidget {
  const StationRankingList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rankingsAsync = ref.watch(stationRankingsProvider(metric: 'revenue', limit: 5));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Top Performing Stations',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Icon(Icons.star, color: Colors.amber, size: 18),
            ],
          ),
          const SizedBox(height: 20),
          rankingsAsync.when(
            data: (rankings) {
              if (rankings.isEmpty) {
                return const Center(child: Text('No ranking data', style: TextStyle(color: Colors.white38)));
              }
              return Column(
                children: rankings.map((r) => _RankingItem(ranking: r)).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Text('Error: $err', style: const TextStyle(color: Colors.red, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _RankingItem extends StatelessWidget {
  final dynamic ranking;
  const _RankingItem({required this.ranking});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: ranking.rank == 1 ? Colors.amber.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${ranking.rank}',
                style: TextStyle(
                  color: ranking.rank == 1 ? Colors.amber : Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              ranking.stationName,
              style: TextStyle(color: Colors.white, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '₹${ranking.metricValue.toStringAsFixed(0)}',
            style: TextStyle(
              color: Colors.greenAccent,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
