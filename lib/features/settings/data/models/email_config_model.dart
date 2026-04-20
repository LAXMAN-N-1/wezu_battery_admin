/// Data Transfer Object for Email Configuration (SMTP) settings.
class EmailConfigModel {
  final String fromName;
  final String fromEmail;
  final String replyToEmail;
  final String smtpHost;
  final int smtpPort;
  final String encryption;
  final String smtpUsername;
  final String smtpPassword;

  const EmailConfigModel({
    this.fromName = '',
    this.fromEmail = '',
    this.replyToEmail = '',
    this.smtpHost = '',
    this.smtpPort = 587,
    this.encryption = 'STARTTLS',
    this.smtpUsername = '',
    this.smtpPassword = '',
  });

  /// Create a copy with modified fields.
  EmailConfigModel copyWith({
    String? fromName,
    String? fromEmail,
    String? replyToEmail,
    String? smtpHost,
    int? smtpPort,
    String? encryption,
    String? smtpUsername,
    String? smtpPassword,
  }) {
    return EmailConfigModel(
      fromName: fromName ?? this.fromName,
      fromEmail: fromEmail ?? this.fromEmail,
      replyToEmail: replyToEmail ?? this.replyToEmail,
      smtpHost: smtpHost ?? this.smtpHost,
      smtpPort: smtpPort ?? this.smtpPort,
      encryption: encryption ?? this.encryption,
      smtpUsername: smtpUsername ?? this.smtpUsername,
      smtpPassword: smtpPassword ?? this.smtpPassword,
    );
  }
}
