import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/inventory_repository.dart';
import 'package:file_picker/file_picker.dart';

final bulkImportProvider = StateNotifierProvider<BulkImportNotifier, BulkImportState>((ref) {
  final repository = InventoryRepository();
  return BulkImportNotifier(repository);
});

class BulkImportState {
  final PlatformFile? selectedFile;
  final bool isParsing;
  final bool isUploading;
  final bool dryRunComplete;
  final int validRows;
  final int totalRows;
  final List<dynamic> errors;
  final bool uploadSuccess;
  final String? errorMessage;

  BulkImportState({
    this.selectedFile,
    this.isParsing = false,
    this.isUploading = false,
    this.dryRunComplete = false,
    this.validRows = 0,
    this.totalRows = 0,
    this.errors = const [],
    this.uploadSuccess = false,
    this.errorMessage,
  });

  BulkImportState copyWith({
    PlatformFile? selectedFile,
    bool? isParsing,
    bool? isUploading,
    bool? dryRunComplete,
    int? validRows,
    int? totalRows,
    List<dynamic>? errors,
    bool? uploadSuccess,
    String? errorMessage,
    bool clearError = false,
    bool clearFile = false,
  }) {
    return BulkImportState(
      selectedFile: clearFile ? null : (selectedFile ?? this.selectedFile),
      isParsing: isParsing ?? this.isParsing,
      isUploading: isUploading ?? this.isUploading,
      dryRunComplete: dryRunComplete ?? this.dryRunComplete,
      validRows: validRows ?? this.validRows,
      totalRows: totalRows ?? this.totalRows,
      errors: errors ?? this.errors,
      uploadSuccess: uploadSuccess ?? this.uploadSuccess,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class BulkImportNotifier extends StateNotifier<BulkImportState> {
  final InventoryRepository _repository;

  BulkImportNotifier(this._repository) : super(BulkImportState());

  void setFile(PlatformFile file) {
    state = state.copyWith(
      selectedFile: file,
      dryRunComplete: false,
      errors: [],
      validRows: 0,
      totalRows: 0,
      uploadSuccess: false,
      clearError: true,
    );
  }

  void clearFile() {
    state = state.copyWith(
      clearFile: true,
      dryRunComplete: false,
      errors: [],
      validRows: 0,
      totalRows: 0,
      uploadSuccess: false,
      clearError: true,
    );
  }

  Future<void> runValidation() async {
    if (state.selectedFile == null) return;

    state = state.copyWith(isParsing: true, clearError: true);
    
    try {
      final file = state.selectedFile!;
      if (file.bytes == null) {
        throw Exception("File bytes not available. Ensure withData is true.");
      }
      final response = await _repository.importBatteries(file.bytes!, file.name, dryRun: true);
      
      final importedCount = response['imported_count'] ?? 0;
      final errorCount = response['error_count'] ?? 0;
      final errors = response['errors'] as List<dynamic>? ?? [];

      state = state.copyWith(
        isParsing: false,
        dryRunComplete: true,
        validRows: importedCount as int,
        totalRows: (importedCount) + (errorCount as int),
        errors: errors,
      );
    } catch (e) {
      state = state.copyWith(
        isParsing: false,
        errorMessage: 'Validation failed: ${e.toString()}',
      );
    }
  }

  Future<void> confirmImport() async {
    if (state.selectedFile == null || !state.dryRunComplete) return;

    state = state.copyWith(isUploading: true, clearError: true);
    
    try {
      final file = state.selectedFile!;
      final response = await _repository.importBatteries(file.bytes!, file.name, dryRun: false);
      
      final importedCount = response['imported_count'] ?? 0;

      state = state.copyWith(
        isUploading: false,
        uploadSuccess: true,
        validRows: importedCount as int, // Final successful inserts
      );
    } catch (e) {
      state = state.copyWith(
        isUploading: false,
        errorMessage: 'Import failed: ${e.toString()}',
      );
    }
  }
}
