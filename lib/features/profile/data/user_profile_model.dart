import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/app_constants.dart';

/// User Profile Model supporting both Student and Organization roles
/// All fields are stored in the /users/{uid} document in Firestore
class UserProfileModel {
  // Immutable fields (read-only, cannot be modified)
  final String uid;
  final String email;
  final String role;
  final DateTime createdAt;

  // Common fields (all roles)
  final String name; // For students: full name, For orgs: organization name

  // Student-specific fields
  final String? collegeName;
  final String? phoneNumber; // Required for both roles
  final String? department;
  final String? yearOfStudy;
  final String? profilePhotoUrl;
  final List<String> subscribedOrgIds;
  final Map<String, DateTime> subscriptionTimestamps; // New field to track subscription time
  final List<String> bookmarkedEventIds;
  final List<String> calendarEventIds;

  // Organization-specific fields
  final String? organizationName; // Required for orgs (same as name)
  final String? officialWebsite;
  final String? organizationDescription;
  final String? address;
  final String? contactPersonName;
  final String? contactPersonPhone;
  final String? logoUrl;
  final bool? verified; // Read-only, set by admin
  
  // Location fields
  final double? latitude;
  final double? longitude;
  final bool isLocationSet;

  // Metadata
  final DateTime? updatedAt;

  UserProfileModel({
    required this.uid,
    required this.email,
    required this.role,
    required this.createdAt,
    required this.name,
    this.collegeName,
    this.phoneNumber,
    this.department,
    this.yearOfStudy,
    this.profilePhotoUrl,
    this.organizationName,
    this.officialWebsite,
    this.organizationDescription,
    this.address,
    this.contactPersonName,
    this.contactPersonPhone,
    this.logoUrl,
    this.verified,
    this.updatedAt,
    this.subscribedOrgIds = const [],
    this.subscriptionTimestamps = const {}, 
    this.bookmarkedEventIds = const [],
    this.calendarEventIds = const [],
    this.latitude,
    this.longitude,
    this.isLocationSet = false,
  });

  /// Create UserProfileModel from Firestore document
  factory UserProfileModel.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;

    return UserProfileModel(
      uid: doc.id,
      email: data['email'] ?? '',
      role: data['role'] ?? '',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      name: data['name'] ?? '',
      // Student fields
      collegeName: data['collegeName'],
      phoneNumber: data['phoneNumber'],
      department: data['department'],
      yearOfStudy: data['yearOfStudy'],
      profilePhotoUrl: data['profilePhotoUrl'],
      // Organization fields
      organizationName: data['organizationName'] ?? data['name'],
      officialWebsite: data['officialWebsite'],
      organizationDescription: data['organizationDescription'],
      address: data['address'],
      contactPersonName: data['contactPersonName'],
      contactPersonPhone: data['contactPersonPhone'],
      logoUrl: data['logoUrl'],
      verified: data['verified'],
      // Metadata
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      subscribedOrgIds: data['subscribedOrgIds'] != null
          ? List<String>.from(data['subscribedOrgIds'])
          : [],
      subscriptionTimestamps: data['subscriptionTimestamps'] != null
          ? (data['subscriptionTimestamps'] as Map<String, dynamic>).map(
              (key, value) => MapEntry(key, (value as Timestamp).toDate()),
            )
          : {},
      bookmarkedEventIds: data['bookmarkedEventIds'] != null
          ? List<String>.from(data['bookmarkedEventIds'])
          : [],
      calendarEventIds: data['calendarEventIds'] != null
          ? List<String>.from(data['calendarEventIds'])
          : [],
      latitude: data['latitude']?.toDouble(),
      longitude: data['longitude']?.toDouble(),
      isLocationSet: data['isLocationSet'] ?? false,
    );
  }

  /// Convert to Firestore map (excludes immutable fields)
  /// Only sends updatable fields to prevent unauthorized modifications
  Map<String, dynamic> toUpdateMap() {
    final map = <String, dynamic>{
      'name': name,
      'phoneNumber': phoneNumber,
      'updatedAt': FieldValue.serverTimestamp(),
      'subscribedOrgIds': subscribedOrgIds,
      'subscriptionTimestamps': subscriptionTimestamps,
      'bookmarkedEventIds': bookmarkedEventIds,
      'calendarEventIds': calendarEventIds,
      'latitude': latitude,
      'longitude': longitude,
      'isLocationSet': isLocationSet,
    };

    // Add role-specific fields based on role
    if (role == AppConstants.roleStudent) {
      if (collegeName != null) map['collegeName'] = collegeName;
      if (department != null) map['department'] = department;
      if (yearOfStudy != null) map['yearOfStudy'] = yearOfStudy;
      if (profilePhotoUrl != null) map['profilePhotoUrl'] = profilePhotoUrl;
    } else if (role == AppConstants.roleOrganization) {
      if (organizationName != null) map['organizationName'] = organizationName;
      if (officialWebsite != null) map['officialWebsite'] = officialWebsite;
      if (organizationDescription != null) {
        map['organizationDescription'] = organizationDescription;
      }
      if (address != null) map['address'] = address;
      if (contactPersonName != null) {
        map['contactPersonName'] = contactPersonName;
      }
      if (contactPersonPhone != null) {
        map['contactPersonPhone'] = contactPersonPhone;
      }
      if (logoUrl != null) map['logoUrl'] = logoUrl;
    }

    return map;
  }

  /// Copy with helper for creating modified instances
  UserProfileModel copyWith({
    String? name,
    String? collegeName,
    String? phoneNumber,
    String? department,
    String? yearOfStudy,
    String? profilePhotoUrl,
    String? organizationName,
    String? officialWebsite,
    String? organizationDescription,
    String? address,
    String? contactPersonName,
    String? contactPersonPhone,
    String? logoUrl,
    DateTime? updatedAt,
    List<String>? subscribedOrgIds,
    Map<String, DateTime>? subscriptionTimestamps,
    List<String>? bookmarkedEventIds,
    List<String>? calendarEventIds,
    double? latitude,
    double? longitude,
    bool? isLocationSet,
  }) {
    return UserProfileModel(
      uid: uid, // Immutable
      email: email, // Immutable
      role: role, // Immutable
      createdAt: createdAt, // Immutable
      name: name ?? this.name,
      collegeName: collegeName ?? this.collegeName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      department: department ?? this.department,
      yearOfStudy: yearOfStudy ?? this.yearOfStudy,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      organizationName: organizationName ?? this.organizationName ?? name ?? this.name,
      officialWebsite: officialWebsite ?? this.officialWebsite,
      organizationDescription:
          organizationDescription ?? this.organizationDescription,
      address: address ?? this.address,
      contactPersonName: contactPersonName ?? this.contactPersonName,
      contactPersonPhone: contactPersonPhone ?? this.contactPersonPhone,
      logoUrl: logoUrl ?? this.logoUrl,
      verified: verified, // Immutable (set by admin)
      updatedAt: updatedAt ?? this.updatedAt,
      subscribedOrgIds: subscribedOrgIds ?? this.subscribedOrgIds,
      subscriptionTimestamps: subscriptionTimestamps ?? this.subscriptionTimestamps,
      bookmarkedEventIds: bookmarkedEventIds ?? this.bookmarkedEventIds,
      calendarEventIds: calendarEventIds ?? this.calendarEventIds,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isLocationSet: isLocationSet ?? this.isLocationSet,
    );
  }

  /// Check if profile is complete based on role requirements
  bool get isComplete {
    if (role == AppConstants.roleStudent) {
      return name.isNotEmpty &&
          (collegeName?.isNotEmpty ?? false) &&
          (phoneNumber?.isNotEmpty ?? false);
    } else if (role == AppConstants.roleOrganization) {
      return name.isNotEmpty &&
          (organizationName?.isNotEmpty ?? false) &&
          (phoneNumber?.isNotEmpty ?? false);
    }
    return false;
  }

  /// Get completion percentage (0-100)
  int get completionPercentage {
    if (role == AppConstants.roleStudent) {
      int filled = 0;
      int total = 5; // name, collegeName, phoneNumber, department, yearOfStudy
      if (name.isNotEmpty) filled++;
      if (collegeName?.isNotEmpty ?? false) filled++;
      if (phoneNumber?.isNotEmpty ?? false) filled++;
      if (department?.isNotEmpty ?? false) filled++;
      if (yearOfStudy?.isNotEmpty ?? false) filled++;
      return (filled / total * 100).round();
    } else if (role == AppConstants.roleOrganization) {
      int filled = 0;
      int total = 7; // name, organizationName, phoneNumber, website, description, address, contactPerson
      if (name.isNotEmpty) filled++;
      if (organizationName?.isNotEmpty ?? false) filled++;
      if (phoneNumber?.isNotEmpty ?? false) filled++;
      if (officialWebsite?.isNotEmpty ?? false) filled++;
      if (organizationDescription?.isNotEmpty ?? false) filled++;
      if (address?.isNotEmpty ?? false) filled++;
      if (contactPersonName?.isNotEmpty ?? false) filled++;
      return (filled / total * 100).round();
    }
    return 0;
  }
}

