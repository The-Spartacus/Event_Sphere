import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
    });
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

  /// Fetch role from Firestore
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

  /// Auth stream (optional use later)
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
