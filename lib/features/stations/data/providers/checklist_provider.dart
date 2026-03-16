import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/maintenance_checklist.dart';
import '../../../../core/api/api_client.dart';

part 'checklist_provider.g.dart';

@riverpod
class ChecklistTemplateNotifier extends _$ChecklistTemplateNotifier {
  @override
  FutureOr<List<ChecklistTemplate>> build() async {
    try {
      final client = ref.read(apiClientProvider);
      final response = await client.get('maintenance/templates');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final templates = data.map((json) => ChecklistTemplate.fromJson(json)).toList();
        if (templates.isNotEmpty) return templates;
      }
    } catch (e) {
      debugPrint('Error fetching templates: $e');
    }

    // Default mock templates if none found on server
    return [
      ChecklistTemplate(
        id: '1',
        name: 'Standard Station Inspection',
        description: 'Monthly routine check for battery swap stations.',
        stationType: 'Standard',
        maintenanceType: 'routine',
        version: 1,
        createdAt: DateTime.now(),
        tasks: [
          const ChecklistTask(id: 't1', title: 'Exterior Cleaning', description: 'Clean the station exterior and display.'),
          const ChecklistTask(id: 't2', title: 'Slot Calibration', description: 'Verify all battery slots are correctly aligned.'),
          const ChecklistTask(id: 't3', title: 'Power System Test', description: 'Check backup power and main circuit health.'),
        ],
      ),
      ChecklistTemplate(
        id: '2',
        name: 'Rapid Charger Overhaul',
        description: 'Quarterly deep maintenance for high-voltage chargers.',
        stationType: 'Rapid',
        maintenanceType: 'repair',
        version: 1,
        createdAt: DateTime.now(),
        tasks: [
          const ChecklistTask(id: 'r1', title: 'Cooling System Check', description: 'Check coolant levels and fan operation.'),
          const ChecklistTask(id: 'r2', title: 'Cable Inspection', description: 'Inspect charging cables for wear or damage.'),
          const ChecklistTask(id: 'r3', title: 'Software Update', description: 'Ensure the latest firmware is installed.'),
        ],
      ),
    ];
  }

  Future<void> addTemplate(ChecklistTemplate template) async {
    state = const AsyncValue.loading();
    try {
      final client = ref.read(apiClientProvider);
      await client.post('maintenance/templates', data: template.toJson());
      ref.invalidateSelf();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateTemplate(ChecklistTemplate template) async {
    state = const AsyncValue.loading();
    try {
      final client = ref.read(apiClientProvider);
      await client.put('maintenance/templates/${template.id}', data: template.toJson());
      ref.invalidateSelf();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteTemplate(String id) async {
    state = const AsyncValue.loading();
    try {
      final client = ref.read(apiClientProvider);
      await client.delete('maintenance/templates/$id');
      ref.invalidateSelf();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

@riverpod
class ChecklistSubmissionNotifier extends _$ChecklistSubmissionNotifier {
  @override
  FutureOr<List<ChecklistSubmission>> build() async {
    try {
      final client = ref.read(apiClientProvider);
      final response = await client.get('maintenance/submissions');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => ChecklistSubmission.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Error fetching submissions: $e');
    }
    return [];
  }

  Future<void> submitChecklist(ChecklistSubmission submission) async {
    state = const AsyncValue.loading();
    try {
      final client = ref.read(apiClientProvider);
      await client.post('maintenance/submissions', data: submission.toJson());
      
      // Refresh local state
      ref.invalidateSelf();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void saveDraft(ChecklistSubmission submission) {
    state = state.whenData((submissions) {
      final exists = submissions.any((s) => s.id == submission.id);
      if (exists) {
        return submissions.map((s) => s.id == submission.id ? submission : s).toList();
      } else {
        return [...submissions, submission];
      }
    });
  }
}
