import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/branding_info_model.dart';
import '../data/models/company_info_model.dart';
import '../data/models/email_config_model.dart';
import '../data/models/maintenance_mode_model.dart';
import '../data/models/notification_settings_model.dart';
import '../data/models/regional_info_model.dart';
import '../data/repositories/branding_settings_repository.dart';
import '../data/repositories/company_settings_repository.dart';
import '../data/repositories/email_settings_repository.dart';
import '../data/repositories/maintenance_settings_repository.dart';
import '../data/repositories/notification_settings_repository.dart';
import '../data/repositories/regional_settings_repository.dart';

/// Tracks which section is active in the General Settings left nav.
final activeSettingsSectionProvider = StateProvider<String>((ref) => 'company_info');

// ─── isDirty Save Bar State ─────────────────────────────────
/// Whether the active section has unsaved changes.
final settingsDirtyProvider = StateProvider<bool>((ref) => false);

/// Whether a save operation is in progress.
final settingsSavingProvider = StateProvider<bool>((ref) => false);

/// Current section's save callback. Registered by each section on mount.
final settingsSaveActionProvider =
    StateProvider<Future<void> Function()?>((_) => null);

/// Current section's discard callback. Registered by each section on mount.
final settingsDiscardActionProvider =
    StateProvider<VoidCallback?>((_) => null);

// ─────────────────────────────────────────
// Company Info Provider — AsyncNotifier pattern
// ─────────────────────────────────────────

/// AsyncNotifier for Company Information CRUD operations.
///
/// Handles loading → data → error states automatically via [AsyncValue].
/// The view layer uses `.when()` for shimmer/content/error rendering.
final companyInfoProvider =
    AsyncNotifierProvider<CompanyInfoNotifier, CompanyInfoModel>(
  CompanyInfoNotifier.new,
);

class CompanyInfoNotifier extends AsyncNotifier<CompanyInfoModel> {
  CompanySettingsRepository get _repo =>
      ref.read(companySettingsRepositoryProvider);

  @override
  Future<CompanyInfoModel> build() async {
    return _repo.getCompanyInfo();
  }

  /// Update company information and refresh state.
  Future<bool> updateCompanyInfo(CompanyInfoModel info) async {
    state = const AsyncValue.loading();
    try {
      final updated = await _repo.updateCompanyInfo(info);
      state = AsyncValue.data(updated);
      return true;
    } catch (e, st) {
      debugPrint('[CompanyInfoNotifier] updateCompanyInfo error: $e');
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Upload a new company logo and update state.
  Future<bool> uploadLogo(List<int> bytes, String filename) async {
    try {
      final url = await _repo.uploadCompanyLogo(bytes, filename);
      if (url != null && state.hasValue) {
        state = AsyncValue.data(state.value!.copyWith(companyLogoUrl: url));
        return true;
      }
      return false;
    } catch (e, st) {
      debugPrint('[CompanyInfoNotifier] uploadLogo error: $e');
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Upload a new favicon and update state.
  Future<bool> uploadFavicon(List<int> bytes, String filename) async {
    try {
      final url = await _repo.uploadFavicon(bytes, filename);
      if (url != null && state.hasValue) {
        state = AsyncValue.data(state.value!.copyWith(faviconUrl: url));
        return true;
      }
      return false;
    } catch (e, st) {
      debugPrint('[CompanyInfoNotifier] uploadFavicon error: $e');
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Reload company info from the API.
  Future<void> reload() async {
    state = const AsyncValue.loading();
    try {
      final data = await _repo.getCompanyInfo();
      state = AsyncValue.data(data);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// ─────────────────────────────────────────
// Branding Info Provider
// ─────────────────────────────────────────

final brandingInfoProvider =
    AsyncNotifierProvider<BrandingInfoNotifier, BrandingInfoModel>(
  BrandingInfoNotifier.new,
);

class BrandingInfoNotifier extends AsyncNotifier<BrandingInfoModel> {
  BrandingSettingsRepository get _repo =>
      ref.read(brandingSettingsRepositoryProvider);

  @override
  Future<BrandingInfoModel> build() async {
    return _repo.getBrandingInfo();
  }

  Future<bool> updateBrandingInfo(BrandingInfoModel info) async {
    state = const AsyncValue.loading();
    try {
      final updated = await _repo.updateBrandingInfo(info);
      state = AsyncValue.data(updated);
      return true;
    } catch (e, st) {
      debugPrint('[BrandingInfoNotifier] updateBrandingInfo error: $e');
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> uploadEmailLogo(List<int> bytes, String filename) async {
    try {
      final url = await _repo.uploadEmailHeaderLogo(bytes, filename);
      if (url != null && state.hasValue) {
        state = AsyncValue.data(state.value!.copyWith(emailHeaderLogoUrl: url));
        return true;
      }
      return false;
    } catch (e, st) {
      debugPrint('[BrandingInfoNotifier] uploadEmailLogo error: $e');
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<void> reload() async {
    state = const AsyncValue.loading();
    try {
      final data = await _repo.getBrandingInfo();
      state = AsyncValue.data(data);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// ─────────────────────────────────────────
// Regional & Language Info Provider
// ─────────────────────────────────────────

final regionalInfoProvider =
    AsyncNotifierProvider<RegionalInfoNotifier, RegionalInfoModel>(
  RegionalInfoNotifier.new,
);

class RegionalInfoNotifier extends AsyncNotifier<RegionalInfoModel> {
  RegionalSettingsRepository get _repo =>
      ref.read(regionalSettingsRepositoryProvider);

  @override
  Future<RegionalInfoModel> build() async {
    return _repo.getRegionalInfo();
  }

  Future<bool> updateRegionalInfo(RegionalInfoModel info) async {
    state = const AsyncValue.loading();
    try {
      final updated = await _repo.updateRegionalInfo(info);
      state = AsyncValue.data(updated);
      return true;
    } catch (e, st) {
      debugPrint('[RegionalInfoNotifier] updateRegionalInfo error: $e');
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<void> reload() async {
    state = const AsyncValue.loading();
    try {
      final data = await _repo.getRegionalInfo();
      state = AsyncValue.data(data);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// ─────────────────────────────────────────
// Email Config Provider
// ─────────────────────────────────────────

final emailConfigProvider =
    AsyncNotifierProvider<EmailConfigNotifier, EmailConfigModel>(
  EmailConfigNotifier.new,
);

class EmailConfigNotifier extends AsyncNotifier<EmailConfigModel> {
  EmailSettingsRepository get _repo =>
      ref.read(emailSettingsRepositoryProvider);

  @override
  Future<EmailConfigModel> build() async {
    return _repo.getEmailConfig();
  }

  Future<bool> updateEmailConfig(EmailConfigModel info) async {
    state = const AsyncValue.loading();
    try {
      final updated = await _repo.updateEmailConfig(info);
      state = AsyncValue.data(updated);
      return true;
    } catch (e, st) {
      debugPrint('[EmailConfigNotifier] updateEmailConfig error: $e');
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> sendTestEmail() async {
    try {
      await _repo.sendTestEmail();
      return true;
    } catch (e) {
      // Don't change the UI state to error just for a test failure, 
      // but return false so the UI can show the toast.
      debugPrint('[EmailConfigNotifier] sendTestEmail failed: $e');
      throw e; // Rethrow so the view catches the error string
    }
  }

  Future<void> reload() async {
    state = const AsyncValue.loading();
    try {
      final data = await _repo.getEmailConfig();
      state = AsyncValue.data(data);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// ─────────────────────────────────────────
// Notification Settings Provider
// ─────────────────────────────────────────

final notificationSettingsProvider = AsyncNotifierProvider<
    NotificationSettingsNotifier, NotificationSettingsModel>(
  NotificationSettingsNotifier.new,
);

class NotificationSettingsNotifier
    extends AsyncNotifier<NotificationSettingsModel> {
  NotificationSettingsRepository get _repo =>
      ref.read(notificationSettingsRepositoryProvider);

  @override
  Future<NotificationSettingsModel> build() async {
    return _repo.getNotificationSettings();
  }

  /// Update notification settings and refresh state.
  Future<bool> updateSettings(NotificationSettingsModel settings) async {
    state = const AsyncValue.loading();
    try {
      final updated = await _repo.updateNotificationSettings(settings);
      state = AsyncValue.data(updated);
      return true;
    } catch (e, st) {
      debugPrint('[NotificationSettingsNotifier] updateSettings error: $e');
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Reload notification settings from the API.
  Future<void> reload() async {
    state = const AsyncValue.loading();
    try {
      final data = await _repo.getNotificationSettings();
      state = AsyncValue.data(data);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// ─────────────────────────────────────────
// Maintenance Mode Provider
// ─────────────────────────────────────────

final maintenanceModeProvider =
    AsyncNotifierProvider<MaintenanceModeNotifier, MaintenanceModeModel>(
  MaintenanceModeNotifier.new,
);

class MaintenanceModeNotifier extends AsyncNotifier<MaintenanceModeModel> {
  MaintenanceSettingsRepository get _repo =>
      ref.read(maintenanceSettingsRepositoryProvider);

  @override
  Future<MaintenanceModeModel> build() async {
    return _repo.getMaintenanceSettings();
  }

  /// Update maintenance mode settings and refresh state.
  Future<bool> updateSettings(MaintenanceModeModel settings) async {
    state = const AsyncValue.loading();
    try {
      final updated = await _repo.updateMaintenanceSettings(settings);
      state = AsyncValue.data(updated);
      return true;
    } catch (e, st) {
      debugPrint('[MaintenanceModeNotifier] updateSettings error: $e');
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Reload maintenance mode settings from the API.
  Future<void> reload() async {
    state = const AsyncValue.loading();
    try {
      final data = await _repo.getMaintenanceSettings();
      state = AsyncValue.data(data);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
