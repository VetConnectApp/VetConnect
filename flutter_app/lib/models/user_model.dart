import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String role; // 'vet' | 'farmer' | 'admin'
  final String phone;

  // Vet-specific fields
  final String license;
  final String specialty;
  final String clinic;
  final String experience;

  // Farmer-specific fields
  final String farmName;
  final String cattleCount;
  final String village;

  // Admin-specific fields
  final String department;
  final String level;

  const UserModel({
    required this.uid,
    required this.email,
    this.displayName = '',
    this.role = 'farmer',
    this.phone = '',
    this.license = '',
    this.specialty = '',
    this.clinic = '',
    this.experience = '',
    this.farmName = '',
    this.cattleCount = '',
    this.village = '',
    this.department = '',
    this.level = '',
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserModel(
      uid: doc.id,
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      role: data['role'] as String? ?? 'farmer',
      phone: data['phone'] as String? ?? '',
      license: data['license'] as String? ?? '',
      specialty: data['specialty'] as String? ?? '',
      clinic: data['clinic'] as String? ?? '',
      experience: data['experience'] as String? ?? '',
      farmName: data['farmName'] as String? ?? '',
      cattleCount: data['cattleCount'] as String? ?? '',
      village: data['village'] as String? ?? '',
      department: data['department'] as String? ?? '',
      level: data['level'] as String? ?? '',
    );
  }

  factory UserModel.fromMap(Map<String, dynamic> data, String uid) {
    return UserModel(
      uid: uid,
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      role: data['role'] as String? ?? 'farmer',
      phone: data['phone'] as String? ?? '',
      license: data['license'] as String? ?? '',
      specialty: data['specialty'] as String? ?? '',
      clinic: data['clinic'] as String? ?? '',
      experience: data['experience'] as String? ?? '',
      farmName: data['farmName'] as String? ?? '',
      cattleCount: data['cattleCount'] as String? ?? '',
      village: data['village'] as String? ?? '',
      department: data['department'] as String? ?? '',
      level: data['level'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'role': role,
      'phone': phone,
      'license': license,
      'specialty': specialty,
      'clinic': clinic,
      'experience': experience,
      'farmName': farmName,
      'cattleCount': cattleCount,
      'village': village,
      'department': department,
      'level': level,
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? role,
    String? phone,
    String? license,
    String? specialty,
    String? clinic,
    String? experience,
    String? farmName,
    String? cattleCount,
    String? village,
    String? department,
    String? level,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      license: license ?? this.license,
      specialty: specialty ?? this.specialty,
      clinic: clinic ?? this.clinic,
      experience: experience ?? this.experience,
      farmName: farmName ?? this.farmName,
      cattleCount: cattleCount ?? this.cattleCount,
      village: village ?? this.village,
      department: department ?? this.department,
      level: level ?? this.level,
    );
  }

  String get initials {
    if (displayName.isNotEmpty) {
      final parts = displayName.trim().split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return parts[0][0].toUpperCase();
    }
    if (email.isNotEmpty) return email[0].toUpperCase();
    return 'U';
  }

  String get roleEmoji {
    switch (role) {
      case 'vet':
        return '🩺';
      case 'admin':
        return '🛡️';
      default:
        return '🚜';
    }
  }

  /// Alias getters for profile_view compatibility
  String get licenseNumber => license;
  String get clinicName => clinic;
  double? get landHoldings => null; // stored in Firestore only; override in fromFirestore if needed
}
