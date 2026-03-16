import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/models/station.dart';

class CameraPlayer extends StatefulWidget {
  final Station station;

  const CameraPlayer({super.key, required this.station});

  @override
  State<CameraPlayer> createState() => _CameraPlayerState();
}

class _CameraPlayerState extends State<CameraPlayer> {
  int _selectedIndex = 0;
  bool _isLoading = true;
  DateTime _lastUpdated = DateTime.now();
  String _searchQuery = '';
  bool _isSearchVisible = false;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _simulateLoading();
  }

  @override
  void didUpdateWidget(CameraPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.station.id != widget.station.id) {
      setState(() {
        _selectedIndex = 0;
        _isLoading = true;
      });
      _simulateLoading();
    }
  }

  void _simulateLoading() {
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _lastUpdated = DateTime.now();
        });
      }
    });
  }

  void _selectCamera(int index, List<StationCamera> filteredCameras) {
    final camera = filteredCameras[index];
    final originalIndex = widget.station.cameras.indexOf(camera);
    if (_selectedIndex == originalIndex) return;
    setState(() {
      _selectedIndex = originalIndex;
      _isLoading = true;
    });
    _simulateLoading();
  }

  @override
  Widget build(BuildContext context) {
    final cameras = widget.station.cameras;

    if (cameras.isEmpty) {
      return Container(
        height: 400,
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.videocam_off, color: Colors.white.withOpacity(0.2), size: 64),
              const SizedBox(height: 16),
              const Text(
                'No Cameras Available for this Station',
                style: TextStyle(color: Colors.white54, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    final allCameras = widget.station.cameras;
    final filteredCameras = allCameras.where((c) => 
      c.name.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();

    // Ensure selected index is still valid or defaults to first filtered
    int activeFilteredIndex = filteredCameras.indexWhere((c) => 
      allCameras.indexOf(c) == _selectedIndex
    );
    if (activeFilteredIndex == -1 && filteredCameras.isNotEmpty) {
      activeFilteredIndex = 0;
    }

    final activeCamera = allCameras.isNotEmpty ? allCameras[_selectedIndex] : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Video Feed Container
        if (activeCamera != null) ...[
          Container(
            height: 400,
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Stack(
              children: [
                // Center Content
                Center(
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.blue)
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.videocam, color: Colors.white.withOpacity(0.2), size: 80),
                            const SizedBox(height: 12),
                            Text(
                              activeCamera.name,
                              style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              activeCamera.streamUrl,
                              style: GoogleFonts.inter(color: Colors.greenAccent.withOpacity(0.7), fontSize: 12),
                            ),
                          ],
                        ),
                ),
                // Live Indicator (Top Left)
                Positioned(
                  top: 16,
                  left: 16,
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'LIVE',
                        style: GoogleFonts.inter(
                          color: Colors.redAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                // Controls (Top Right)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Row(
                    children: [
                      if (allCameras.length > 5)
                        IconButton(
                          icon: Icon(
                            _isSearchVisible ? Icons.search_off : Icons.search,
                            color: _isSearchVisible ? Colors.blue : Colors.white70,
                            size: 22,
                          ),
                          onPressed: () {
                            setState(() {
                              _isSearchVisible = !_isSearchVisible;
                              if (!_isSearchVisible) {
                                _searchQuery = '';
                                _searchController.clear();
                              }
                            });
                          },
                          tooltip: 'Toggle Search',
                        ),
                      IconButton(
                        icon: const Icon(Icons.fullscreen, color: Colors.white70, size: 24),
                        onPressed: () => _showFullScreenView(context, activeCamera),
                        tooltip: 'Fullscreen',
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.white70, size: 22),
                        onPressed: () {
                          setState(() => _isLoading = true);
                          _simulateLoading();
                        },
                        tooltip: 'Refresh',
                      ),
                    ],
                  ),
                ),
                // Last Heartbeat (Bottom Right)
                if (!_isLoading)
                  Positioned(
                    bottom: 12,
                    right: 16,
                    child: Text(
                      'Updated: ${_lastUpdated.hour.toString().padLeft(2, '0')}:${_lastUpdated.minute.toString().padLeft(2, '0')}:${_lastUpdated.second.toString().padLeft(2, '0')}',
                      style: GoogleFonts.inter(color: Colors.white54, fontSize: 11),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          
          // Internal Scrollable Section for Search and Camera Buttons
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200),
            child: Scrollbar(
              controller: _scrollController,
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.only(right: 12), // Space for scrollbar
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Search/Filter Bar
                    if (_isSearchVisible)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) => setState(() => _searchQuery = val),
                          autofocus: true,
                          style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Search cameras...',
                            hintStyle: GoogleFonts.inter(color: Colors.white24),
                            prefixIcon: const Icon(Icons.search, color: Colors.white24, size: 18),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.close, color: Colors.white24, size: 16),
                              onPressed: () {
                                setState(() {
                                  _isSearchVisible = false;
                                  _searchQuery = '';
                                  _searchController.clear();
                                });
                              },
                            ),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.05),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                            ),
                          ),
                        ),
                      ),
                    
                    // Camera Selector Buttons
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(
                        filteredCameras.length, 
                        (index) => _buildCameraButton(
                          index, 
                          filteredCameras[index], 
                          filteredCameras[index].id == (activeCamera.id),
                          filteredCameras
                        )
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCameraButton(int index, StationCamera camera, bool isActive, List<StationCamera> filteredList) {
    return SizedBox(
      width: 140, // Fixed width for consistent feel
      child: InkWell(
        onTap: () => _selectCamera(index, filteredList),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: isActive ? Colors.blue.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isActive ? Colors.blue : Colors.white.withOpacity(0.1),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            camera.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: isActive ? Colors.blue : Colors.white70,
              fontSize: 12,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  void _showFullScreenView(BuildContext context, StationCamera camera) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.videocam, color: Colors.white.withOpacity(0.1), size: 120),
                    const SizedBox(height: 24),
                    Text(
                      camera.name,
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      camera.streamUrl,
                      style: GoogleFonts.inter(color: Colors.greenAccent.withOpacity(0.7), fontSize: 16),
                    ),
                    const SizedBox(height: 48),
                    const CircularProgressIndicator(color: Colors.blue),
                    const SizedBox(height: 16),
                    Text(
                      'Connecting to live stream...',
                      style: GoogleFonts.inter(color: Colors.white54, fontSize: 14),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 20,
                right: 20,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 32),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              Positioned(
                top: 24,
                left: 24,
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'LIVE FULLSCREEN',
                      style: GoogleFonts.inter(
                        color: Colors.redAccent,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
