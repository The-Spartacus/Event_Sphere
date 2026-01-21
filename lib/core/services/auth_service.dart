import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../constants/api_endpoints.dart';
import '../constants/app_constants.dart';

enum AuthState {
  unauthenticated,
  student,
  organization,
  admin,
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Check authentication + role
  Future<AuthState> checkAuthState() async {
    final user = _auth.currentUser;
    if (user == null) {
      return AuthState.unauthenticated;
    }

    final role = await getUserRole(user.uid);

    switch (role) {
      case AppConstants.roleStudent:
        return AuthState.student;
      case AppConstants.roleOrganization:
        return AuthState.organization;
      case AppConstants.roleAdmin:
      case AppConstants.roleSuperAdmin:
        return AuthState.admin;
      default:
        return AuthState.unauthenticated;
    }
  }

  /// Register new user
  Future<void> register({
    required String email,
    required String password,
    required String name,
    required String role,
    // Optional fields
    String? phoneNumber,
    String? collegeName,
    String? department,
    String? yearOfStudy,
    String? organizationName,
    String? officialWebsite,
    String? organizationDescription,
    String? address,
    String? contactPersonName,
    String? contactPersonPhone,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await _firestore
        .collection(ApiEndpoints.users)
        .doc(credential.user!.uid)
        .set({
      'name': name,
      'email': email,
      'role': role,
      'createdAt': FieldValue.serverTimestamp(),
      'phoneNumber': phoneNumber,
      'collegeName': collegeName,
      'department': department,
      'yearOfStudy': yearOfStudy,
      'organizationName': organizationName ?? (role == AppConstants.roleOrganization ? name : null),
      'officialWebsite': officialWebsite,
      'organizationDescription': organizationDescription,
      'address': address,
      'contactPersonName': contactPersonName,
      'contactPersonPhone': contactPersonPhone,
    });

    if (role == AppConstants.roleOrganization) {
      await _firestore
          .collection(ApiEndpoints.organizations)
          .doc(credential.user!.uid)
          .set({
        'name': name,
        'email': email,
        'verified': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Register new user without logging out the current user (Secondary App)
  Future<void> registerSecondaryUser({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    FirebaseApp? secondaryApp;
    try {
      // 1. Initialize a secondary app
      secondaryApp = await Firebase.initializeApp(
        name: 'SecondaryApp',
        options: Firebase.app().options,
      );

      // 2. Create user using the secondary app's auth instance
      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
      final credential = await secondaryAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 3. Save user details to Firestore (using the PRIMARY app's Firestore)
      // We use the primary firestore because we want to write to the main DB.
      await _firestore
          .collection(ApiEndpoints.users)
          .doc(credential.user!.uid)
          .set({
        'name': name,
        'email': email,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // No organization logic needed here as this is primarily for admin creation
      // but if needed we can add it. Assuming this is for Sub-Admins.

    } finally {
      // 4. Delete the secondary app to clean up
      await secondaryApp?.delete();
    }
  }

  /// Login user
  Future<void> login({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Logout user
  Future<void> logout() async {
    await _auth.signOut();
  }
  Future<String?> getUserRole(String uid) async {
    final snapshot = await _firestore
        .collection(ApiEndpoints.users)
        .doc(uid)
        .get();

    if (!snapshot.exists) return null;
    return snapshot.data()?['role'];
  }

  /// Current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  /// Change password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw FirebaseAuthException(code: 'user-not-found');

    final cred = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );

    // Re-authenticate
    await user.reauthenticateWithCredential(cred);

    // Update
    await user.updatePassword(newPassword);
  }

  /// Auth stream (optional use later)
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
