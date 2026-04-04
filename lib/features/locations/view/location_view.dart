import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../provider/location_provider.dart';
import '../model/location_model.dart';

class LocationView extends ConsumerWidget {
  const LocationView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(locationProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(40),
          child: Wrap(spacing: 16, runSpacing: 16, alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Location Management',
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              
              ElevatedButton.icon(
                onPressed: () => _showAddDialog(context, ref),
                icon: const Icon(Icons.add, size: 18),
                label: Text('Add ${state.currentLevel.name.toUpperCase()}'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Breadcrumbs
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: _buildBreadcrumbs(ref, state),
        ),

        const SizedBox(height: 24),

        // Grid of Locations
        Expanded(
          child: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 250,
                          childAspectRatio: 2.5,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                    itemCount: state.nodes.length,
                    itemBuilder: (context, index) {
                      final node = state.nodes[index];
                      return _buildLocationCard(ref, node, state);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildBreadcrumbs(WidgetRef ref, LocationState state) {
    List<Widget> children = [
      _breadcrumbItem(
        'Global',
        onTap: () => ref.read(locationProvider.notifier).resetToLevel(-1),
      ),
    ];

    for (int i = 0; i < state.path.length; i++) {
      children.add(
        const Icon(Icons.chevron_right, color: Colors.white24, size: 16),
      );
      children.add(
        _breadcrumbItem(
          state.path[i].name,
          onTap: () => ref.read(locationProvider.notifier).resetToLevel(i),
        ),
      );
    }

    return Row(children: children);
  }

  Widget _breadcrumbItem(String label, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildLocationCard(
    WidgetRef ref,
    LocationNode node,
    LocationState state,
  ) {
    final hasNext = state.currentLevel.next != null;

    return InkWell(
      onTap: hasNext
          ? () => ref.read(locationProvider.notifier).dive(node)
          : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.location_on_outlined,
                color: Colors.blue.shade400,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                node.name,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (hasNext)
              const Icon(Icons.chevron_right, color: Colors.white24, size: 18),
          ],
        ),
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(
          'Add New ${ref.read(locationProvider).currentLevel.name}',
          style: const TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Enter name',
            hintStyle: TextStyle(color: Colors.white24),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(locationProvider.notifier).addLocation(controller.text);
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
