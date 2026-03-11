import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import '../data/repositories/inventory_repository.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

class BatteryImportModal extends ConsumerStatefulWidget {
  const BatteryImportModal({super.key});

  @override
  ConsumerState<BatteryImportModal> createState() => _BatteryImportModalState();
}

class _BatteryImportModalState extends ConsumerState<BatteryImportModal> {
  late final InventoryRepository _repository;
  int _currentStep = 0;
  bool _isLoading = false;
  
  PlatformFile? _pickedFile;
  Map<String, dynamic>? _validationResults;

  @override
  void initState() {
    super.initState();
    _repository = ref.read(inventoryRepositoryProvider);
  }

  void _nextStep() {
    setState(() {
      if (_currentStep < 3) _currentStep++;
    });
  }

  void _prevStep() {
    setState(() {
      if (_currentStep > 0) _currentStep--;
    });
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );

    if (result != null) {
      setState(() {
        _pickedFile = result.files.first;
      });
      _validateFile();
    }
  }

  Future<void> _validateFile() async {
    if (_pickedFile == null || _pickedFile!.bytes == null) return;

    setState(() {
      _isLoading = true;
      _currentStep = 1; 
    });

    try {
      final results = await _repository.importBatteries(
        _pickedFile!.bytes!.toList(), 
        _pickedFile!.name,
        dryRun: true,
      );
      setState(() {
        _validationResults = results;
        _isLoading = false;
        _currentStep = 2; // Move to results step
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Validation failed: $e'), backgroundColor: Colors.redAccent)
        );
      }
    }
  }

  Future<void> _confirmImport() async {
    if (_pickedFile == null || _pickedFile!.bytes == null) return;

    setState(() => _isLoading = true);

    try {
      final results = await _repository.importBatteries(
        _pickedFile!.bytes!.toList(), 
        _pickedFile!.name,
        dryRun: false,
      );
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${results['success_count']} batteries imported successfully!'),
            backgroundColor: Colors.green,
          )
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e'), backgroundColor: Colors.redAccent)
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 800,
        height: 600,
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Bulk Import Batteries',
                  style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
            const SizedBox(height: 32),
            
            // Stepper Header
            Row(
              children: [
                _buildStepIndicator(0, 'Template'),
                _buildStepDivider(),
                _buildStepIndicator(1, 'Upload'),
                _buildStepDivider(),
                _buildStepIndicator(2, 'Validation'),
                _buildStepDivider(),
                _buildStepIndicator(3, 'Confirm'),
              ],
            ),
            const SizedBox(height: 32),
            
            // Step Content
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : _buildStepContent(),
            ),
            
            const SizedBox(height: 24),
            
            // Footer Navigation
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentStep > 0 && _currentStep < 3)
                  TextButton(
                    onPressed: _isLoading ? null : _prevStep,
                    child: const Text('Back', style: TextStyle(color: Colors.white70)),
                  )
                else
                  const SizedBox.shrink(),
                
                if (_currentStep < 3)
                  ElevatedButton(
                    onPressed: (_currentStep == 2 && (_validationResults?['success_count'] ?? 0) > 0)
                      ? _nextStep
                      : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Continue', style: TextStyle(color: Colors.white)),
                  )
                else
                  ElevatedButton(
                    onPressed: _isLoading ? null : _confirmImport,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Perform Import', style: TextStyle(color: Colors.white)),
                  )
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator(int stepIndex, String title) {
    bool isActive = _currentStep == stepIndex;
    bool isCompleted = _currentStep > stepIndex;
    
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive ? Colors.blueAccent : (isCompleted ? Colors.green : Colors.transparent),
            shape: BoxShape.circle,
            border: Border.all(color: isActive || isCompleted ? Colors.transparent : Colors.white38),
          ),
          child: Center(
            child: isCompleted 
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : Text('${stepIndex + 1}', style: TextStyle(color: isActive ? Colors.white : Colors.white54, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: isActive || isCompleted ? Colors.white : Colors.white54,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStepDivider() {
    return Expanded(
      child: Container(
        height: 1,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        color: Colors.white.withValues(alpha: 0.1),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.file_download_outlined, size: 64, color: Colors.white24),
              const SizedBox(height: 24),
              Text('Download the CSV template', style: GoogleFonts.outfit(fontSize: 20, color: Colors.white)),
              const SizedBox(height: 8),
              const Text('Ensure you stick to the required columns: serial_number, manufacturer, location_type, etc.', style: TextStyle(color: Colors.white54)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _nextStep,
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: const Text('I have the file, proceed to Upload', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: 0.1), foregroundColor: Colors.white),
              ),
            ],
          ),
        );
      case 1:
        return Center(
          child: InkWell(
            onTap: _pickFile,
            child: Container(
              width: 400,
              padding: const EdgeInsets.all(48),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3), width: 2, style: BorderStyle.solid),
                borderRadius: BorderRadius.circular(16),
                color: Colors.white.withValues(alpha: 0.02),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_upload_outlined, size: 64, color: Colors.blueAccent),
                  const SizedBox(height: 24),
                  Text(_pickedFile?.name ?? 'Click to browse CSV file', style: const TextStyle(color: Colors.white, fontSize: 16)),
                  const SizedBox(height: 8),
                  const Text('Accepts .csv files only', style: TextStyle(color: Colors.white38, fontSize: 12)),
                ],
              ),
            ),
          ),
        );
      case 2:
        final errors = _validationResults?['errors'] as List? ?? [];
        final successCount = _validationResults?['success_count'] ?? 0;
        final errorCount = _validationResults?['error_count'] ?? 0;

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: errorCount > 0 ? Colors.red.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8)
              ),
              child: Row(
                children: [
                  Icon(errorCount > 0 ? Icons.error_outline : Icons.check_circle_outline, 
                    color: errorCount > 0 ? Colors.redAccent : Colors.greenAccent),
                  const SizedBox(width: 8),
                  Text('$successCount valid rows, $errorCount errors found.', 
                    style: TextStyle(color: errorCount > 0 ? Colors.redAccent : Colors.greenAccent, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (errorCount > 0)
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: errors.length,
                    itemBuilder: (context, index) {
                      final err = errors[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'Row ${err['row']}: ${err['error']}',
                          style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                        ),
                      );
                    },
                  ),
                ),
              )
            else
              const Expanded(
                child: Center(
                  child: Text('All rows are valid! You can now proceed to import.', style: TextStyle(color: Colors.white54)),
                ),
              ),
          ],
        );
      case 3:
        final successCount = _validationResults?['success_count'] ?? 0;
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_outline, size: 80, color: Colors.green),
              const SizedBox(height: 24),
              Text('Ready to Import', style: GoogleFonts.outfit(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Text(
                '$successCount batteries will be added to your inventory.\nAny rows with errors will be skipped.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
              ),
            ],
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
