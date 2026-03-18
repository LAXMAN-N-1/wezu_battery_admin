import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/models/station.dart';
import '../data/models/station_specs.dart';
import '../data/providers/stations_provider.dart';

// -------------------------------------------------------
// Provider: loads specs for a given stationId
// -------------------------------------------------------
final stationSpecsProvider = FutureProvider.family<StationSpecs, int>((
  ref,
  stationId,
) async {
  final repo = ref.read(stationRepositoryProvider);
  return repo.getSpecs(stationId);
});

// -------------------------------------------------------
// Entry point — shows as a modal bottom sheet
// -------------------------------------------------------
void showStationSpecsSheet(BuildContext context, Station station) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => StationSpecsView(station: station),
  );
}

class StationSpecsView extends ConsumerStatefulWidget {
  final Station station;
  const StationSpecsView({super.key, required this.station});

  @override
  ConsumerState<StationSpecsView> createState() => _StationSpecsViewState();
}

class _StationSpecsViewState extends ConsumerState<StationSpecsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  StationSpecs? _specs;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadSpecs();
  }

  Future<void> _loadSpecs() async {
    final repo = ref.read(stationRepositoryProvider);
    final specs = await repo.getSpecs(widget.station.id);
    if (mounted) setState(() => _specs = specs);
  }

  Future<void> _save() async {
    if (_specs == null) return;
    setState(() => _saving = true);
    final repo = ref.read(stationRepositoryProvider);
    await repo.saveSpecs(widget.station.id, _specs!);
    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Specs saved for ${widget.station.name}'),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;

    return Container(
      height: h * 0.9,
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 16, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.electrical_services,
                    color: Colors.blue,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.station.name,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Technical Specifications',
                        style: GoogleFonts.inter(
                          color: Colors.white38,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Total power pill
                if (_specs != null) _PowerPill(specs: _specs!),
                const SizedBox(width: 8),
                // Save button
                ElevatedButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_rounded, size: 16),
                  label: Text(_saving ? 'Saving…' : 'Save'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Tabs
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white38,
              indicatorColor: Colors.blue,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              labelStyle: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              tabs: const [
                Tab(icon: Icon(Icons.battery_full, size: 16), text: 'Capacity'),
                Tab(
                  icon: Icon(Icons.electric_bolt, size: 16),
                  text: 'Chargers',
                ),
                Tab(icon: Icon(Icons.security, size: 16), text: 'Safety'),
                Tab(icon: Icon(Icons.thermostat, size: 16), text: 'Environ'),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Tab content
          Expanded(
            child: _specs == null
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.blue),
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _CapacityTab(
                        specs: _specs!,
                        station: widget.station,
                        onChanged: (s) => setState(() => _specs = s),
                      ),
                      _ChargersTab(
                        specs: _specs!,
                        onChanged: (s) => setState(() => _specs = s),
                      ),
                      _SafetyTab(
                        specs: _specs!,
                        onChanged: (s) => setState(() => _specs = s),
                      ),
                      _EnvironmentTab(
                        specs: _specs!,
                        onChanged: (s) => setState(() => _specs = s),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------
// Live total-power pill in the header
// -------------------------------------------------------
class _PowerPill extends StatelessWidget {
  final StationSpecs specs;
  const _PowerPill({required this.specs});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.purple.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.flash_on, size: 12, color: Colors.purple),
          const SizedBox(width: 4),
          Text(
            '${specs.totalPowerConsumptionKw.toStringAsFixed(1)} kW',
            style: GoogleFonts.inter(
              color: Colors.purple,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================
// TAB 1 — CAPACITY
// =============================================
class _CapacityTab extends StatelessWidget {
  final StationSpecs specs;
  final Station station;
  final ValueChanged<StationSpecs> onChanged;

  const _CapacityTab({
    required this.specs,
    required this.station,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader('Battery Capacity', Icons.battery_charging_full),
          const SizedBox(height: 16),

          // Stat row
          Row(
            children: [
              _StatCard(
                'Total Slots',
                '${station.totalSlots}',
                Colors.blue,
                Icons.grid_view,
              ),
              const SizedBox(width: 12),
              _StatCard(
                'Available',
                '${station.availableBatteries}',
                Colors.green,
                Icons.battery_full,
              ),
              const SizedBox(width: 12),
              _StatCard(
                'Empty',
                '${station.emptySlots}',
                Colors.orange,
                Icons.battery_0_bar,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Max capacity slider
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Max Battery Capacity',
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${specs.maxBatteryCapacity} batteries',
                        style: GoogleFonts.outfit(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: Colors.blue,
                    inactiveTrackColor: Colors.blue.withValues(alpha: 0.15),
                    thumbColor: Colors.blue,
                    overlayColor: Colors.blue.withValues(alpha: 0.1),
                  ),
                  child: Slider(
                    value: specs.maxBatteryCapacity.toDouble(),
                    min: 1,
                    max: 100,
                    divisions: 99,
                    onChanged: (v) => onChanged(
                      specs.copyWith(maxBatteryCapacity: v.round()),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '1',
                      style: GoogleFonts.inter(
                        color: Colors.white24,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      '100',
                      style: GoogleFonts.inter(
                        color: Colors.white24,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Utilization bar
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Utilization',
                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: specs.maxBatteryCapacity == 0
                        ? 0
                        : station.availableBatteries / specs.maxBatteryCapacity,
                    minHeight: 12,
                    backgroundColor: Colors.white10,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      station.availableBatteries / specs.maxBatteryCapacity >
                              0.7
                          ? Colors.green
                          : station.availableBatteries /
                                    specs.maxBatteryCapacity >
                                0.3
                          ? Colors.orange
                          : Colors.red,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${station.availableBatteries} / ${specs.maxBatteryCapacity} batteries',
                      style: GoogleFonts.inter(
                        color: Colors.white38,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      specs.maxBatteryCapacity == 0
                          ? '0%'
                          : '${(station.availableBatteries / specs.maxBatteryCapacity * 100).round()}%',
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================
// TAB 2 — CHARGERS
// =============================================
class _ChargersTab extends StatelessWidget {
  final StationSpecs specs;
  final ValueChanged<StationSpecs> onChanged;

  const _ChargersTab({required this.specs, required this.onChanged});

  void _addCharger() {
    onChanged(
      specs.copyWith(
        chargers: [
          ...specs.chargers,
          const ChargerConfig(
            type: ChargerType.standard,
            powerKw: 7.4,
            chargingSpeedKmh: 40,
            efficiencyPercent: 85,
            count: 1,
          ),
        ],
      ),
    );
  }

  void _removeCharger(int index) {
    final updated = List<ChargerConfig>.from(specs.chargers)..removeAt(index);
    onChanged(specs.copyWith(chargers: updated));
  }

  void _updateCharger(int index, ChargerConfig updated) {
    final list = List<ChargerConfig>.from(specs.chargers);
    list[index] = updated;
    onChanged(specs.copyWith(chargers: list));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SectionHeader('Charger Configurations', Icons.electric_bolt),
              const Spacer(),
              // Summary pill
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.purple.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  '⚡ Total: ${specs.totalPowerConsumptionKw.toStringAsFixed(1)} kW',
                  style: GoogleFonts.inter(
                    color: Colors.purple,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          ...specs.chargers.asMap().entries.map(
            (entry) => _ChargerCard(
              index: entry.key,
              config: entry.value,
              onUpdate: (updated) => _updateCharger(entry.key, updated),
              onRemove: () => _removeCharger(entry.key),
              canRemove: specs.chargers.length > 1,
            ),
          ),

          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _addCharger,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Charger Type'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blue,
                side: BorderSide(color: Colors.blue.withValues(alpha: 0.4)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChargerCard extends StatelessWidget {
  final int index;
  final ChargerConfig config;
  final ValueChanged<ChargerConfig> onUpdate;
  final VoidCallback onRemove;
  final bool canRemove;

  const _ChargerCard({
    required this.index,
    required this.config,
    required this.onUpdate,
    required this.onRemove,
    required this.canRemove,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${config.type.icon} Charger ${index + 1}',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              // Total power for this config
              Text(
                '${config.totalPowerKw.toStringAsFixed(1)} kW total',
                style: GoogleFonts.inter(color: Colors.purple, fontSize: 12),
              ),
              const SizedBox(width: 8),
              if (canRemove)
                GestureDetector(
                  onTap: onRemove,
                  child: const Icon(
                    Icons.remove_circle_outline,
                    color: Colors.redAccent,
                    size: 20,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Charger type dropdown
          _SpecRow(
            label: 'Type',
            child: DropdownButtonFormField<ChargerType>(
              initialValue: config.type,
              dropdownColor: const Color(0xFF1E293B),
              style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
              decoration: _dropdownDecoration(),
              items: ChargerType.values
                  .map(
                    (t) => DropdownMenuItem(
                      value: t,
                      child: Text('${t.icon} ${t.label}'),
                    ),
                  )
                  .toList(),
              onChanged: (v) => onUpdate(config.copyWith(type: v)),
            ),
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: _SpecRow(
                  label: 'Power (kW)',
                  child: _NumField(
                    value: config.powerKw,
                    onChanged: (v) => onUpdate(config.copyWith(powerKw: v)),
                    suffix: 'kW',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SpecRow(
                  label: 'Units',
                  child: _NumField(
                    value: config.count.toDouble(),
                    onChanged: (v) =>
                        onUpdate(config.copyWith(count: v.round())),
                    isInt: true,
                    suffix: 'pcs',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: _SpecRow(
                  label: 'Speed (km/h)',
                  child: _NumField(
                    value: config.chargingSpeedKmh,
                    onChanged: (v) =>
                        onUpdate(config.copyWith(chargingSpeedKmh: v)),
                    suffix: 'km/h',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SpecRow(
                  label: 'Efficiency',
                  child: _NumField(
                    value: config.efficiencyPercent,
                    onChanged: (v) => onUpdate(
                      config.copyWith(efficiencyPercent: v.clamp(0, 100)),
                    ),
                    suffix: '%',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================
// TAB 3 — SAFETY
// =============================================
class _SafetyTab extends StatelessWidget {
  final StationSpecs specs;
  final ValueChanged<StationSpecs> onChanged;

  const _SafetyTab({required this.specs, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final selected = specs.safetyFeatures.toSet();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader('Safety Features', Icons.security),
          const SizedBox(height: 8),
          Text(
            '${selected.length} of ${kSafetyFeatureOptions.length} features enabled',
            style: GoogleFonts.inter(color: Colors.white38, fontSize: 12),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            child: Column(
              children: kSafetyFeatureOptions.map((feature) {
                final isOn = selected.contains(feature);
                return CheckboxListTile(
                  value: isOn,
                  checkColor: Colors.white,
                  activeColor: Colors.green.shade600,
                  side: BorderSide(color: Colors.white24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  title: Text(
                    feature,
                    style: GoogleFonts.inter(
                      color: isOn ? Colors.white : Colors.white60,
                      fontSize: 14,
                    ),
                  ),
                  secondary: isOn
                      ? const Icon(
                          Icons.verified,
                          color: Colors.green,
                          size: 18,
                        )
                      : const SizedBox.shrink(),
                  onChanged: (v) {
                    final updated = Set<String>.from(selected);
                    if (v == true) {
                      updated.add(feature);
                    } else {
                      updated.remove(feature);
                    }
                    onChanged(specs.copyWith(safetyFeatures: updated.toList()));
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================
// TAB 4 — ENVIRONMENT & PHOTOS
// =============================================
class _EnvironmentTab extends StatelessWidget {
  final StationSpecs specs;
  final ValueChanged<StationSpecs> onChanged;

  const _EnvironmentTab({required this.specs, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final rangeValues = RangeValues(specs.minTempC, specs.maxTempC);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader('Operating Temperature', Icons.thermostat),
          const SizedBox(height: 16),

          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _TempBadge('Min', specs.minTempC, Colors.blue),
                    const Icon(
                      Icons.arrow_forward,
                      color: Colors.white24,
                      size: 18,
                    ),
                    _TempBadge('Max', specs.maxTempC, Colors.orange),
                  ],
                ),
                const SizedBox(height: 8),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: Colors.blue,
                    inactiveTrackColor: Colors.white10,
                    thumbColor: Colors.white,
                    rangeThumbShape: const RoundRangeSliderThumbShape(
                      enabledThumbRadius: 10,
                    ),
                    overlayColor: Colors.blue.withValues(alpha: 0.1),
                  ),
                  child: RangeSlider(
                    values: rangeValues,
                    min: -20,
                    max: 70,
                    divisions: 90,
                    onChanged: (rv) => onChanged(
                      specs.copyWith(minTempC: rv.start, maxTempC: rv.end),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '-20°C',
                      style: GoogleFonts.inter(
                        color: Colors.white24,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      '70°C',
                      style: GoogleFonts.inter(
                        color: Colors.white24,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _SectionHeader('Station Photos', Icons.photo_library_outlined),
          const SizedBox(height: 12),
          Text(
            'Photo upload will be available when cloud storage is configured.',
            style: GoogleFonts.inter(color: Colors.white38, fontSize: 12),
          ),
          const SizedBox(height: 16),

          // Photo placeholder grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount:
                3 + (specs.photoUrls.isEmpty ? 0 : specs.photoUrls.length),
            itemBuilder: (_, i) {
              if (i < specs.photoUrls.length) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: const Center(
                    child: Icon(Icons.image, color: Colors.white38, size: 32),
                  ),
                );
              }
              // Add photo placeholder
              return DashedAddPhoto(
                onTap: () {
                  // Placeholder — cloud storage integration pending
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Photo upload requires cloud storage configuration',
                      ),
                      backgroundColor: Color(0xFF1E293B),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TempBadge extends StatelessWidget {
  final String label;
  final double temp;
  final Color color;
  const _TempBadge(this.label, this.temp, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(color: Colors.white38, fontSize: 11),
        ),
        const SizedBox(height: 4),
        Text(
          '${temp.round()}°C',
          style: GoogleFonts.outfit(
            color: color,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class DashedAddPhoto extends StatelessWidget {
  final VoidCallback onTap;
  const DashedAddPhoto({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white12,
            style: BorderStyle.solid,
            width: 1.5,
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add_photo_alternate_outlined,
                color: Colors.white24,
                size: 28,
              ),
              SizedBox(height: 4),
              Text(
                'Add Photo',
                style: TextStyle(color: Colors.white24, fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================
// SHARED SMALL WIDGETS
// =============================================
class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader(this.title, this.icon);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.blue),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? margin;
  const _SectionCard({required this.child, this.margin});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? EdgeInsets.zero,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: child,
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const _StatCard(this.label, this.value, this.color, this.icon);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 6),
            Text(
              value,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.inter(color: Colors.white38, fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _SpecRow extends StatelessWidget {
  final String label;
  final Widget child;
  const _SpecRow({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(color: Colors.white54, fontSize: 11),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _NumField extends StatefulWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final String suffix;
  final bool isInt;

  const _NumField({
    required this.value,
    required this.onChanged,
    required this.suffix,
    this.isInt = false,
  });

  @override
  State<_NumField> createState() => _NumFieldState();
}

class _NumFieldState extends State<_NumField> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
      text: widget.isInt
          ? widget.value.round().toString()
          : widget.value.toStringAsFixed(1),
    );
  }

  @override
  void didUpdateWidget(_NumField old) {
    super.didUpdateWidget(old);
    final newText = widget.isInt
        ? widget.value.round().toString()
        : widget.value.toStringAsFixed(1);
    if (_ctrl.text != newText && !_ctrl.selection.isValid) {
      _ctrl.text = newText;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _ctrl,
      style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
      keyboardType: TextInputType.numberWithOptions(decimal: !widget.isInt),
      inputFormatters: widget.isInt
          ? [FilteringTextInputFormatter.digitsOnly]
          : [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
      decoration: _inputDecoration(widget.suffix),
      onChanged: (v) {
        final parsed = double.tryParse(v);
        if (parsed != null) widget.onChanged(parsed);
      },
    );
  }
}

InputDecoration _inputDecoration(String suffix) => InputDecoration(
  suffixText: suffix,
  suffixStyle: const TextStyle(color: Colors.white38, fontSize: 12),
  filled: true,
  fillColor: Colors.black.withValues(alpha: 0.25),
  isDense: true,
  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: BorderSide.none,
  ),
);

InputDecoration _dropdownDecoration() => InputDecoration(
  filled: true,
  fillColor: Colors.black.withValues(alpha: 0.25),
  isDense: true,
  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: BorderSide.none,
  ),
);
