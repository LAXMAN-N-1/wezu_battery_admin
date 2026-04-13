import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import '../data/models/banner.dart' as model;
import '../provider/cms_providers.dart';
import '../../../core/widgets/glass_components.dart';

class BannerEditorView extends ConsumerStatefulWidget {
  final model.Banner? banner;
  const BannerEditorView({super.key, this.banner});

  @override
  ConsumerState<BannerEditorView> createState() => _BannerEditorViewState();
}

class _BannerEditorViewState extends ConsumerState<BannerEditorView> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  late TextEditingController _titleController;
  late TextEditingController _imageUrlController;
  late TextEditingController _ctaTextController;
  late TextEditingController _linkController;
  late TextEditingController _priorityController;
  
  // State
  String _type = 'Home Carousel';
  String _targetAudience = 'All Users';
  String _linkType = 'External URL';
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isActive = true;
  bool _isSaving = false;
  bool _showAspectRatioWarning = false;
  String? _lastValidatedUrl;
  String _actualRatio = 'Unknown';
  double? _uploadProgress;
  String? _pickedFileName;

  @override
  void initState() {
    super.initState();
    final b = widget.banner;
    _titleController = TextEditingController(text: b?.title ?? '');
    _imageUrlController = TextEditingController(text: b?.imageUrl ?? '');
    _ctaTextController = TextEditingController(text: b?.ctaText ?? 'Learn More');
    _linkController = TextEditingController(text: b?.externalUrl ?? b?.deepLink ?? '');
    _priorityController = TextEditingController(text: b?.priority.toString() ?? '1');
    
    if (b != null) {
      _type = b.type;
      _targetAudience = b.targetAudience;
      _linkType = b.externalUrl != null ? 'External URL' : (b.deepLink != null ? 'In-app Screen' : 'No Link');
      _startDate = b.startDate;
      _endDate = b.endDate;
      _isActive = b.isActive;
    }

    _titleController.addListener(() => setState(() {}));
    _imageUrlController.addListener(() {
      setState(() {});
      _validateImage(_imageUrlController.text);
    });
    _ctaTextController.addListener(() => setState(() {}));
    
    if (_imageUrlController.text.isNotEmpty) {
      _validateImage(_imageUrlController.text);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _imageUrlController.dispose();
    _ctaTextController.dispose();
    _linkController.dispose();
    _priorityController.dispose();
    super.dispose();
  }

  Future<void> _save({bool isDraft = false}) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    
    final data = {
      'title': _titleController.text,
      'image_url': _imageUrlController.text,
      'type': _type,
      'target_audience': _targetAudience,
      'cta_text': _ctaTextController.text,
      'priority': int.tryParse(_priorityController.text) ?? 1,
      'is_active': isDraft ? false : _isActive,
      'start_date': _startDate?.toIso8601String(),
      'end_date': _endDate?.toIso8601String(),
      if (_linkType == 'In-app Screen') 'deep_link': _linkController.text,
    };

    if (_startDate != null && _endDate != null && _endDate!.isBefore(_startDate!)) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error: End Date must be after Start Date')));
      setState(() => _isSaving = false);
      return;
    }

    try {
      if (widget.banner == null) {
        await ref.read(cmsRepositoryProvider).createBanner(data);
      } else {
        await ref.read(cmsRepositoryProvider).updateBanner(widget.banner!.id, data);
      }
      ref.invalidate(bannerProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      setState(() {
        _uploadProgress = 0.1;
        _pickedFileName = result.files.single.name;
      });

      // Simulate upload progress
      for (int i = 1; i <= 10; i++) {
        await Future.delayed(const Duration(milliseconds: 150));
        if (mounted) setState(() => _uploadProgress = i / 10);
      }

      if (mounted) {
        setState(() {
          // In a real app, this would be the URL from the server
          _imageUrlController.text = 'https://picsum.photos/1200/675?random=${DateTime.now().millisecondsSinceEpoch}';
          _uploadProgress = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      child: Column(
        children: [
          _buildTopBar(),
          Expanded(
            child: Row(
              children: [
                // Form Section (70%)
                Expanded(
                  flex: 7,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle('General Configuration'),
                          const SizedBox(height: 24),
                          _buildFieldLabel('Internal Title'),
                          TextFormField(
                            controller: _titleController,
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputDeco('e.g. Summer Sale 2026'),
                            validator: (v) => v!.isEmpty ? 'Title is required' : null,
                          ),
                          const SizedBox(height: 24),
                          _buildFieldLabel('Banner Type'),
                          _buildTypeDropdown(),
                          const SizedBox(height: 32),
                          _buildSectionTitle('Visual Assets'),
                          const SizedBox(height: 24),
                          _buildImageSection(),
                          const SizedBox(height: 32),
                          _buildSectionTitle('Action & Link'),
                          const SizedBox(height: 24),
                          _buildLinkSection(),
                          const SizedBox(height: 32),
                          _buildSectionTitle('Schedule & Targeting'),
                          const SizedBox(height: 24),
                          _buildScheduleSection(),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ),
                // Preview Section (30%)
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: const BoxDecoration(
                      border: Border(left: BorderSide(color: Colors.white10)),
                      color: Colors.black12,
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: _buildLivePreview(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white10))),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white70),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 16),
          Text(
            widget.banner == null ? 'NEW BANNER' : 'EDIT BANNER',
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          TextButton(
            onPressed: _isSaving ? null : () => _save(isDraft: true),
            child: const Text('SAVE AS DRAFT', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: _isSaving ? null : () => _save(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: _isSaving
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('PUBLISH BANNER', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.inter(color: const Color(0xFF3B82F6), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(label, style: const TextStyle(color: Colors.white38, fontSize: 13)),
    );
  }

  Widget _buildTypeDropdown() {
    final types = ['Home Carousel', 'Popup', 'Top Notification', 'Floating Card'];
    return DropdownButtonFormField<String>(
      value: _type,
      dropdownColor: const Color(0xFF1E293B),
      style: const TextStyle(color: Colors.white),
      decoration: _inputDeco(''),
      items: types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
      onChanged: (v) => setState(() => _type = v!),
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildFieldLabel('Banner Image URL'),
            if (_imageUrlController.text.isNotEmpty)
              Row(
                children: [
                  TextButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.refresh, size: 14, color: Color(0xFF3B82F6)),
                    label: const Text('REPLACE', style: TextStyle(fontSize: 11, color: Color(0xFF3B82F6))),
                  ),
                  TextButton.icon(
                    onPressed: () => setState(() => _imageUrlController.clear()),
                    icon: const Icon(Icons.delete_outline, size: 14, color: Colors.redAccent),
                    label: const Text('REMOVE', style: TextStyle(fontSize: 11, color: Colors.redAccent)),
                  ),
                ],
              ),
          ],
        ),
        TextFormField(
          controller: _imageUrlController,
          style: const TextStyle(color: Colors.white),
          decoration: _inputDeco('https://example.com/banner.jpg'),
          validator: (v) => v!.isEmpty ? 'Image URL is required' : null,
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: _pickImage,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.02),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: _uploadProgress != null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.cloud_upload, color: Color(0xFF3B82F6), size: 32),
                      const SizedBox(height: 16),
                      Text('Uploading $_pickedFileName...', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: 200,
                        child: LinearProgressIndicator(
                          value: _uploadProgress,
                          backgroundColor: Colors.white10,
                          valueColor: const AlwaysStoppedAnimation(Color(0xFF3B82F6)),
                        ),
                      ),
                    ],
                  )
                : _imageUrlController.text.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(_imageUrlController.text, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 48, color: Colors.white10)),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.cloud_upload_outlined, size: 40, color: Colors.white10),
                          const SizedBox(height: 12),
                          const Text('Click to upload or Drag and drop image', style: TextStyle(color: Colors.white24, fontSize: 13)),
                          const SizedBox(height: 4),
                          Text('Recommended: 1200x675 (16:9)', style: TextStyle(color: Colors.white.withOpacity(0.05), fontSize: 11)),
                        ],
                      ),
          ),
        ),
        if (_showAspectRatioWarning) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Aspect Ratio Mismatch',
                        style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Expected 16:9 (1200×675px). Your image ratio: $_actualRatio. Distortion may occur.',
                        style: TextStyle(color: Colors.amber.withOpacity(0.8), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _showAspectRatioWarning = false),
                  child: const Text('DISMISS', style: TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _validateImage(String url) {
    if (url.isEmpty || url == _lastValidatedUrl) return;
    if (!url.startsWith('http')) return;
    
    _lastValidatedUrl = url;
    final image = Image.network(url);
    image.image.resolve(const ImageConfiguration()).addListener(
      ImageStreamListener((info, _) {
        final double w = info.image.width.toDouble();
        final double h = info.image.height.toDouble();
        final ratio = w / h;
        final is16x9 = (ratio - (16 / 9)).abs() < 0.15;
        
        if (mounted) {
          setState(() {
            _actualRatio = '${w.toInt()}:${h.toInt()} (${ratio.toStringAsFixed(2)})';
            _showAspectRatioWarning = !is16x9;
          });
        }
      }, onError: (e, _) {
        if (mounted) setState(() => _showAspectRatioWarning = false);
      }),
    );
  }

  Widget _buildLinkSection() {
    return Column(
      children: [
        Row(
          children: ['External URL', 'In-app Screen', 'No Link'].map((t) {
            final isSelected = _linkType == t;
            return GestureDetector(
              onTap: () => setState(() => _linkType = t),
              child: Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF3B82F6).withOpacity(0.1) : Colors.transparent,
                  border: Border.all(color: isSelected ? const Color(0xFF3B82F6).withOpacity(0.4) : Colors.white10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(t, style: TextStyle(color: isSelected ? const Color(0xFF3B82F6) : Colors.white24, fontSize: 13, fontWeight: FontWeight.bold)),
              ),
            );
          }).toList(),
        ),
        if (_linkType != 'No Link') ...[
          const SizedBox(height: 16),
          TextFormField(
            controller: _linkController,
            style: const TextStyle(color: Colors.white),
            decoration: _inputDeco(_linkType == 'External URL' ? 'https://...' : 'Choose screen (Home, Wallet, Profile...)'),
          ),
        ],
        const SizedBox(height: 16),
        _buildFieldLabel('Button Text (CTA)'),
        TextFormField(
          controller: _ctaTextController,
          style: const TextStyle(color: Colors.white),
          decoration: _inputDeco('e.g. SHOP NOW'),
        ),
      ],
    );
  }

  Widget _buildScheduleSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildDatePicker('Start Date', _startDate, (d) => setState(() => _startDate = d)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDatePicker('End Date', _endDate, (d) => setState(() => _endDate = d), firstDate: _startDate),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel('Display Priority'),
                  TextFormField(
                    controller: _priorityController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDeco('1 (Highest)').copyWith(
                      suffixIcon: const Tooltip(
                        message: 'Priority 1 is the highest. Lower numbers appear first in the app carousel.',
                        child: Icon(Icons.info_outline, size: 16, color: Colors.white24),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel('Target Audience'),
                  DropdownButtonFormField<String>(
                    value: _targetAudience,
                    dropdownColor: const Color(0xFF1E293B),
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDeco(''),
                    items: ['All Users', 'New Users (30d)', 'Premium Users', 'Specific City'].map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                    onChanged: (v) => setState(() => _targetAudience = v!),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDatePicker(String label, DateTime? value, Function(DateTime) onPicked, {DateTime? firstDate}) {
    final fmt = DateFormat('MMM dd, yyyy');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(label),
        InkWell(
          onTap: () async {
            final now = DateTime.now();
            final d = await showDatePicker(
              context: context,
              initialDate: value ?? (firstDate ?? now),
              firstDate: firstDate ?? now.subtract(const Duration(days: 365)),
              lastDate: now.add(const Duration(days: 365 * 2)),
              builder: (ctx, child) => Theme(data: Theme.of(context).copyWith(colorScheme: const ColorScheme.dark(primary: Color(0xFF3B82F6))), child: child!),
            );
            if (d != null) onPicked(d);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
            child: Row(
              children: [
                Icon(Icons.calendar_month, size: 16, color: value != null ? const Color(0xFF3B82F6) : Colors.white24),
                const SizedBox(width: 12),
                Text(value == null ? '--/--/----' : fmt.format(value), style: TextStyle(color: value != null ? Colors.white : Colors.white24, fontSize: 13)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLivePreview() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildFieldLabel('LIVE PREVIEW'),
          const SizedBox(height: 24),
          // iPhone Frame
          Container(
            width: 280,
            height: 560,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: Colors.white24, width: 6),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 40, offset: const Offset(0, 20))],
            ),
            child: Column(
              children: [
                _buildPhoneNotch(),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    child: _buildBannerInsideApp(),
                  ),
                ),
                _buildPhoneHomeIndicator(),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Simulating iPhone 15 Pro Display', style: TextStyle(color: Colors.white.withOpacity(0.05), fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildPhoneNotch() {
    return Container(
      width: 100,
      height: 20,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(10)),
    );
  }

  Widget _buildPhoneHomeIndicator() {
    return Container(
      width: 100,
      height: 4,
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(2)),
    );
  }

  Widget _buildBannerInsideApp() {
    // This renders based on the selected TYPE
    if (_type == 'Popup') {
      return Center(
        child: Container(
          width: 220,
          height: 320,
          decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white12)),
          child: Column(
            children: [
              Expanded(
                child: _imageUrlController.text.isNotEmpty
                  ? ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(20)), child: Image.network(_imageUrlController.text, fit: BoxFit.cover))
                  : const Center(child: Icon(Icons.image, color: Colors.white10)),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(_titleController.text.isEmpty ? 'Banner Title' : _titleController.text, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    if (_ctaTextController.text.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(color: const Color(0xFF3B82F6), borderRadius: BorderRadius.circular(8)),
                        child: Text(_ctaTextController.text, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ).animate().scale(delay: 200.ms, duration: 400.ms, curve: Curves.easeOutBack),
      );
    }

    // Default: Home Carousel or Floating Card logic
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Featured Promotions', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          height: 140,
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (_imageUrlController.text.isNotEmpty)
                ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(_imageUrlController.text, fit: BoxFit.cover)),
              Container(
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.center, colors: [Colors.black.withOpacity(0.7), Colors.transparent])),
              ),
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_titleController.text.isEmpty ? 'Banner Title' : _titleController.text, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    if (_ctaTextController.text.isNotEmpty)
                      _chip(_ctaTextController.text, const Color(0xFF3B82F6), textColor: Colors.white),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Quick Services', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
            Text('View All', style: TextStyle(color: Color(0xFF3B82F6), fontSize: 10)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(4, (i) => Container(width: 48, height: 48, decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(12)))),
        ),
      ],
    );
  }

  Widget _chip(String text, Color bg, {Color? textColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: TextStyle(color: textColor ?? Colors.white38, fontSize: 8, fontWeight: FontWeight.bold)),
    );
  }

  InputDecoration _inputDeco(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white10),
      filled: true,
      fillColor: Colors.white.withOpacity(0.03),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white10)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white10)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF3B82F6))),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
