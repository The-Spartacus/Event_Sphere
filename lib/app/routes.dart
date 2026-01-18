import 'package:flutter/material.dart';

// Auth
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/auth/presentation/role_selection_screen.dart';
import '../features/auth/presentation/splash_screen.dart';
import '../features/auth/presentation/onboarding_screen.dart';

// Student / Events
import '../features/student/student_home.dart';
import '../features/events/presentation/event_list_screen.dart';
import '../features/events/presentation/event_detail_screen.dart';
import '../features/events/presentation/event_filter_screen.dart';
import '../features/events/data/event_model.dart';
import '../features/tickets/presentation/ticket_screen.dart';

// Certificates
import '../features/certificates/certificate_vault_screen.dart';

// Organization 
import '../features/organization/org_home.dart';
import '../features/organization/org_dashboard_screen.dart';
import '../features/organization/create_event_screen.dart';
import '../features/organization/org_events_list_screen.dart';
import '../features/organization/edit_event_screen.dart';
import '../features/organization/participants_screen.dart';
import '../features/organization/scan_qr_screen.dart';
import '../features/organization/public_org_profile_screen.dart';

// Profile
import '../features/profile/presentation/student_profile_screen.dart';
import '../features/profile/presentation/organization_profile_screen.dart';

// Admin
import '../features/admin/admin_home.dart';
import '../features/admin/verify_org_screen.dart';
import '../features/admin/analytics_screen.dart';
import '../features/admin/create_admin_screen.dart';

class AppRoutes {
  // Route names
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String roleSelect = '/role-select';

  static const String studentHome = '/student/home';
  static const String eventDetails = '/events/details';
  static const String eventFilter = '/events/filter';
  static const String certificates = '/certificates';
  static const String profile = '/profile';
  static const String ticket = '/ticket';

  static const String orgHome = '/org/home';
  static const String createEvent = '/org/create-event';
  static const String orgEventsList = '/org/events-list';
  static const String editEvent = '/org/edit-event';
  static const String participants = '/org/participants';
  static const String scanQr = '/org/scan-qr';
  static const String publicOrgProfile = '/student/org-profile';
  static const String categoryEvents = '/events/category';

  static const String adminHome = '/admin/home';
  static const String verifyOrg = '/admin/verify-org';
  static const String analytics = '/admin/analytics';
  static const String createAdmin = '/admin/create-admin';

  // Route generator
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return _page(const SplashScreen());

      case onboarding:
        return _page(const OnboardingScreen());

      case login:
        return _page(const LoginScreen());

      case register:
        return _page(const RegisterScreen());

      case roleSelect:
        return _page(const RoleSelectionScreen());

      case studentHome:
        return _page(const StudentHome());

      case eventDetails:
        return _page(
          EventDetailScreen(eventId: settings.arguments as String),
        );

      case eventFilter:
        return _page(const EventFilterScreen());

      case certificates:
        return _page(const CertificateVaultScreen());

      case ticket:
        return _page(
          TicketScreen(event: settings.arguments as EventModel),
        );

      case profile:
        // Route arguments should contain role ('student' or 'organization')
        final role = settings.arguments as String?;
        if (role == 'organization') {
          return _page(const OrganizationProfileScreen());
        }
        return _page(const StudentProfileScreen());

      case orgHome:
        return _page(const OrgHome());

      case createEvent:
        return _page(const CreateEventScreen());

      case orgEventsList:
        return _page(const OrgEventsListScreen());

      case editEvent:
        return _page(
          EditEventScreen(eventId: settings.arguments as String),
        );

      case participants:
        return _page(
          ParticipantsScreen(eventId: settings.arguments as String),
        );

      case scanQr:
        return _page(
          ScanQrScreen(eventId: settings.arguments as String),
        );

      case publicOrgProfile:
        return _page(
          PublicOrgProfileScreen(organizationId: settings.arguments as String),
        );

      case categoryEvents:
        return _page(
          EventListScreen(initialCategory: settings.arguments as String?),
        );

      case adminHome:
        return _page(const AdminHome());

      case verifyOrg:
        return _page(const VerifyOrgScreen());

      case analytics:
        return _page(const AnalyticsScreen());

      case createAdmin:
        return _page(const CreateAdminScreen());

      default:
        return _page(
          const Scaffold(
            body: Center(child: Text('Route not found')),
          ),
        );
    }
  }

  // Helper routes (used in app.dart)
  static Widget loginWidget() => const LoginScreen();
  static Widget studentHomeWidget() => const EventListScreen();
  static Widget organizationHomeWidget() => const OrgDashboardScreen();
  static Widget adminHomeWidget() => const AdminHome();

  // Private helper
  static MaterialPageRoute _page(Widget child) {
    return MaterialPageRoute(builder: (_) => child);
  }
}
