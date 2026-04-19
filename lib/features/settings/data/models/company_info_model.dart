/// Data Transfer Object for Company Information settings.
///
/// Maps to the `/api/v1/admin/settings/company-info` endpoint.
/// All fields are strongly typed — no raw Maps.
class CompanyInfoModel {
  /// Unique identifier from the backend.
  final int? id;

  /// Company display name — shown in email headers, invoices, app branding.
  final String companyName;

  /// Primary company email address.
  final String companyEmail;

  /// Support phone number with country code.
  final String supportPhone;

  /// Company physical address (max 300 chars).
  final String companyAddress;

  /// Company website URL.
  final String companyWebsite;

  /// URL to the company logo image (160×60px display).
  final String? companyLogoUrl;

  /// URL to the favicon image (32×32px display).
  final String? faviconUrl;

  const CompanyInfoModel({
    this.id,
    this.companyName = '',
    this.companyEmail = '',
    this.supportPhone = '',
    this.companyAddress = '',
    this.companyWebsite = '',
    this.companyLogoUrl,
    this.faviconUrl,
  });

  /// Create a [CompanyInfoModel] from JSON response.
  factory CompanyInfoModel.fromJson(Map<String, dynamic> json) {
    return CompanyInfoModel(
      id: json['id'] as int?,
      companyName: json['company_name']?.toString() ?? '',
      companyEmail: json['company_email']?.toString() ?? '',
      supportPhone: json['support_phone']?.toString() ?? '',
      companyAddress: json['company_address']?.toString() ?? '',
      companyWebsite: json['company_website']?.toString() ?? '',
      companyLogoUrl: json['company_logo_url']?.toString(),
      faviconUrl: json['favicon_url']?.toString(),
    );
  }

  /// Serialize to JSON for API payload.
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'company_name': companyName,
      'company_email': companyEmail,
      'support_phone': supportPhone,
      'company_address': companyAddress,
      'company_website': companyWebsite,
      if (companyLogoUrl != null) 'company_logo_url': companyLogoUrl,
      if (faviconUrl != null) 'favicon_url': faviconUrl,
    };
  }

  /// Create a copy with modified fields.
  CompanyInfoModel copyWith({
    int? id,
    String? companyName,
    String? companyEmail,
    String? supportPhone,
    String? companyAddress,
    String? companyWebsite,
    String? companyLogoUrl,
    String? faviconUrl,
  }) {
    return CompanyInfoModel(
      id: id ?? this.id,
      companyName: companyName ?? this.companyName,
      companyEmail: companyEmail ?? this.companyEmail,
      supportPhone: supportPhone ?? this.supportPhone,
      companyAddress: companyAddress ?? this.companyAddress,
      companyWebsite: companyWebsite ?? this.companyWebsite,
      companyLogoUrl: companyLogoUrl ?? this.companyLogoUrl,
      faviconUrl: faviconUrl ?? this.faviconUrl,
    );
  }
}
