class AppConstants {
  AppConstants._(); // Prevent instantiation

  // User roles
  static const String roleStudent = 'student';
  static const String roleOrganization = 'organization';
  static const String roleAdmin = 'admin';
  static const String roleSuperAdmin = 'super_admin';

  // Event categories
  static const List<String> eventCategories = [
    'Seminars & Workshops',
    'Internship Programs',
    'Certificate Courses',
    'College Events',
    'Training & Skill Programs',
  ];

  // Location types
  static const String locationOnline = 'online';
  static const String locationOffline = 'offline';
  static const String locationHybrid = 'hybrid';

  // Common labels
  static const String paid = 'Paid';
  static const String free = 'Free';
}
