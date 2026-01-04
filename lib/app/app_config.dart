class AppConfig {
  AppConfig._(); // Private constructor

  // App info
  static const String appName = 'Event Sphere';

  // UI spacing
  static const double defaultPadding = 16.0;
  static const double borderRadius = 12.0;

  // Pagination / limits
  static const int eventPageLimit = 20;

  // Date formats
  static const String displayDateFormat = 'dd MMM yyyy';

  // File constraints
  static const int maxCertificateFileSizeMB = 5;
}
