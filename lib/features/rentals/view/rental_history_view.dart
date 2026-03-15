import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/admin_ui_components.dart';
import '../data/models/rental_model.dart';
import '../data/repositories/rental_repository.dart';

class RentalHistoryView extends StatefulWidget {
  const RentalHistoryView({super.key});

  @override
  State<RentalHistoryView> createState() => _RentalHistoryViewState();
}

class _RentalHistoryViewState extends State<RentalHistoryView> {
  final RentalRepository _repository = RentalRepository();
  List<Rental> _history = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final history = await _repository.getRentalHistory(search: _searchQuery.isNotEmpty ? _searchQuery : null);
    setState(() {
      _history = history;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Rental History', style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text('Complete log of all past rental transactions and activities.', style: GoogleFonts.inter(fontSize: 16, color: Colors.white54)),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.download_outlined),
                label: const Text('Export CSV'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E293B)),
              ),
            ],
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 32),

          Row(
            children: [
              Expanded(
                child: TextField(
                  style: const TextStyle(color: Colors.white),
                  onChanged: (v) {
                    _searchQuery = v;
                    _loadData();
                  },
                  decoration: InputDecoration(
                    hintText: 'Search by rental ID, user ID...',
                    prefixIcon: const Icon(Icons.search, color: Colors.white38),
                    filled: true,
                    fillColor: const Color(0xFF1E293B),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white70),
                onPressed: _loadData,
              ),
            ],
          ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
          const SizedBox(height: 24),

          Expanded(
            child: AdvancedCard(
              padding: EdgeInsets.zero,
              child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _history.isEmpty
                    ? const Center(child: Text('No history found.', style: TextStyle(color: Colors.white54)))
                    : AdvancedTable(
                        columns: const ['ID', 'User', 'Start Date', 'End Date', 'Amount', 'Status', 'Actions'],
                        rows: _history.map((r) {
                          return [
                            Text('#${r.id}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                            Text(r.userName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            Text(DateFormat('MMM dd, yyyy').format(r.startTime), style: const TextStyle(color: Colors.white54)),
                            Text(r.endTime != null ? DateFormat('MMM dd, yyyy').format(r.endTime!) : '-', style: const TextStyle(color: Colors.white54)),
                            Text('₹${r.totalAmount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white)),
                            StatusBadge(status: r.status),
                            IconButton(icon: const Icon(Icons.visibility_outlined, color: Color(0xFF3B82F6), size: 20), onPressed: () {}),
                          ];
                        }).toList(),
                      ),
            ),
          ).animate().fadeIn(duration: 500.ms, delay: 200.ms).slideY(begin: 0.05),
        ],
      ),
    );
  }
}
