import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/audit_repository.dart';

class SecuritySettingsState {
  final bool isLoading;
  final bool isSaving;
  final Map<String, dynamic> settings; // Current settings from server
  final Map<String, dynamic> localSettings; // Pending changes
  final String? error;

  SecuritySettingsState({
    this.isLoading = false,
    this.isSaving = false,
    this.settings = const {},
    this.localSettings = const {},
    this.error,
  });

  bool get isDirty => localSettings.isNotEmpty;

  SecuritySettingsState copyWith({
    bool? isLoading,
    bool? isSaving,
    Map<String, dynamic>? settings,
    Map<String, dynamic>? localSettings,
    String? error,
    bool clearLocal = false,
  }) {
    return SecuritySettingsState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      settings: settings ?? this.settings,
      localSettings: clearLocal ? const {} : (localSettings ?? this.localSettings),
      error: error ?? this.error,
    );
  }
}

class SecuritySettingsNotifier extends StateNotifier<SecuritySettingsState> {
  final AuditRepository _repository;

  SecuritySettingsNotifier(this._repository) : super(SecuritySettingsState()) {
    loadSettings();
  }

  Future<void> loadSettings() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final settings = await _repository.getSecuritySettings();
      state = state.copyWith(isLoading: false, settings: settings, clearLocal: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void updateLocalSetting(String key, dynamic value) {
    final newLocal = Map<String, dynamic>.from(state.localSettings);
    if (state.settings[key] == value) {
      newLocal.remove(key);
    } else {
      newLocal[key] = value;
    }
    state = state.copyWith(localSettings: newLocal);
  }

  Future<void> saveChanges() async {
    if (!state.isDirty) return;
    state = state.copyWith(isSaving: true, error: null);
    try {
      await _repository.updateSecuritySettings(state.localSettings);
      await loadSettings();
      state = state.copyWith(isSaving: false);
    } catch (e) {
      state = state.copyWith(isSaving: false, error: 'Failed to save settings: $e');
    }
  }

  void discardChanges() {
    state = state.copyWith(clearLocal: true);
  }

  Future<void> forceLogoutAll() async {
    // Implementation for session invalidation
    await _repository.updateSecuritySettings({'force_logout_all': true});
  }

  void addIpToWhitelist(String ip, String label) {
    final rawList = state.localSettings['ip_whitelist'] ?? state.settings['ip_whitelist'] ?? [];
    final List<dynamic> currentItems = rawList is List ? rawList : [];
    
    final newList = currentItems.map((e) {
      if (e is Map) return Map<String, dynamic>.from(e);
      if (e is String) return {'ip': e, 'label': 'Migrated'};
      return <String, dynamic>{};
    }).toList();

    newList.add({'ip': ip, 'label': label});
    updateLocalSetting('ip_whitelist', newList);
  }

  void removeIpFromWhitelist(int index) {
    final rawList = state.localSettings['ip_whitelist'] ?? state.settings['ip_whitelist'] ?? [];
    final List<dynamic> currentItems = rawList is List ? rawList : [];
    
    final newList = currentItems.map((e) {
      if (e is Map) return Map<String, dynamic>.from(e);
      if (e is String) return {'ip': e, 'label': 'Migrated'};
      return <String, dynamic>{};
    }).toList();

    if (index >= 0 && index < newList.length) {
      newList.removeAt(index);
      updateLocalSetting('ip_whitelist', newList);
    }
  }
}

final securitySettingsProvider = StateNotifierProvider<SecuritySettingsNotifier, SecuritySettingsState>((ref) {
  final repo = ref.watch(auditRepositoryProvider);
  return SecuritySettingsNotifier(repo);
});
