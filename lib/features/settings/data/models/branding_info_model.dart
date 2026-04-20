/// Data Transfer Object for Branding Information settings.
///
/// Maps to the `/api/v1/admin/settings/general` endpoint specifically for branding keys.
class BrandingInfoModel {
  /// Hex string for primary brand color (e.g. #2563EB).
  final String primaryColor;

  /// Hex string for secondary brand color (e.g. #1E40AF).
  final String secondaryColor;

  /// Theme mode setting: 'light', 'dark', or 'system'.
  final String themeMode;

  /// URL to the email header logo.
  final String? emailHeaderLogoUrl;

  const BrandingInfoModel({
    this.primaryColor = '#2563EB',
    this.secondaryColor = '#1E40AF',
    this.themeMode = 'system',
    this.emailHeaderLogoUrl,
  });

  /// Create a copy with modified fields.
  BrandingInfoModel copyWith({
    String? primaryColor,
    String? secondaryColor,
    String? themeMode,
    String? emailHeaderLogoUrl,
  }) {
    return BrandingInfoModel(
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      themeMode: themeMode ?? this.themeMode,
      emailHeaderLogoUrl: emailHeaderLogoUrl ?? this.emailHeaderLogoUrl,
    );
  }
}
