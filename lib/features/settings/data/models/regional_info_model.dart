/// Data Transfer Object for Regional & Language Information settings.
///
/// Maps to the `/api/v1/admin/settings/general` endpoint specifically for regional keys.
class RegionalInfoModel {
  final String language;
  final String timezone;
  final String dateFormat;
  final String timeFormat;
  final String currency;
  final String numberFormat;

  const RegionalInfoModel({
    this.language = 'English',
    this.timezone = 'Asia/Kolkata (IST +05:30)',
    this.dateFormat = 'DD/MM/YYYY',
    this.timeFormat = '12-hour',
    this.currency = 'INR (₹)',
    this.numberFormat = '1,234.56',
  });

  /// Create a copy with modified fields.
  RegionalInfoModel copyWith({
    String? language,
    String? timezone,
    String? dateFormat,
    String? timeFormat,
    String? currency,
    String? numberFormat,
  }) {
    return RegionalInfoModel(
      language: language ?? this.language,
      timezone: timezone ?? this.timezone,
      dateFormat: dateFormat ?? this.dateFormat,
      timeFormat: timeFormat ?? this.timeFormat,
      currency: currency ?? this.currency,
      numberFormat: numberFormat ?? this.numberFormat,
    );
  }
}
