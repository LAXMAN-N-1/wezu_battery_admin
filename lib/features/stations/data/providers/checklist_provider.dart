import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/api/api_client.dart';
import '../models/maintenance_checklist.dart';

part 'checklist_provider.g.dart';

@riverpod
class ChecklistTemplateNotifier extends _$ChecklistTemplateNotifier {
  Future<List<ChecklistTemplate>> _fetchTemplates() async {
    final client = ref.read(apiClientProvider);
    final response = await client.get('/api/v1/admin/stations/maintenance/checklists/templates');
    final payload = response.data is Map<String, dynamic>
        ? response.data as Map<String, dynamic>
        : Map<String, dynamic>.from(response.data as Map);
    final items = payload['items'] is List ? payload['items'] as List : const <dynamic>[];
    return items
        .whereType<Map>()
        .map((raw) => ChecklistTemplate.fromJson(Map<String, dynamic>.from(raw)))
        .toList();
  }

  @override
  FutureOr<List<ChecklistTemplate>> build() async => _fetchTemplates();

  Future<void> addTemplate(ChecklistTemplate template) async {
    state = const AsyncValue.loading();
    try {
      final client = ref.read(apiClientProvider);
      await client.post(
        '/api/v1/admin/stations/maintenance/checklists/templates',
        data: {
          'name': template.name,
          'description': template.description,
          'station_type': template.stationType,
          'maintenance_type': template.maintenanceType,
          'tasks': template.tasks.map((task) => task.toJson()).toList(),
          'version': template.version,
          'is_active': true,
        },
      );
      state = AsyncValue.data(await _fetchTemplates());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateTemplate(ChecklistTemplate template) async {
    state = const AsyncValue.loading();
    try {
      final client = ref.read(apiClientProvider);
      await client.put(
        '/api/v1/admin/stations/maintenance/checklists/templates/${template.id}',
        data: {
          'name': template.name,
          'description': template.description,
          'station_type': template.stationType,
          'maintenance_type': template.maintenanceType,
          'tasks': template.tasks.map((task) => task.toJson()).toList(),
          'version': template.version,
          'is_active': true,
        },
      );
      state = AsyncValue.data(await _fetchTemplates());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteTemplate(String id) async {
    state = const AsyncValue.loading();
    try {
      final client = ref.read(apiClientProvider);
      await client.delete('/api/v1/admin/stations/maintenance/checklists/templates/$id');
      state = AsyncValue.data(await _fetchTemplates());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

@riverpod
class ChecklistSubmissionNotifier extends _$ChecklistSubmissionNotifier {
  Future<List<ChecklistSubmission>> _fetchSubmissions() async {
    final client = ref.read(apiClientProvider);
    final response = await client.get('/api/v1/admin/stations/maintenance/checklists/submissions');
    final payload = response.data is Map<String, dynamic>
        ? response.data as Map<String, dynamic>
        : Map<String, dynamic>.from(response.data as Map);
    final items = payload['items'] is List ? payload['items'] as List : const <dynamic>[];
    return items
        .whereType<Map>()
        .map((raw) => ChecklistSubmission.fromJson(Map<String, dynamic>.from(raw)))
        .toList();
  }

  @override
  FutureOr<List<ChecklistSubmission>> build() async => _fetchSubmissions();

  Future<void> submitChecklist(ChecklistSubmission submission) async {
    state = const AsyncValue.loading();
    try {
      final client = ref.read(apiClientProvider);
      await client.post(
        '/api/v1/admin/stations/maintenance/checklists/submissions',
        data: submission.toJson(),
      );
      state = AsyncValue.data(await _fetchSubmissions());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  void saveDraft(ChecklistSubmission submission) {
    debugPrint('Checklist drafts are not persisted by the backend.');
  }
}
