import 'package:flutter/foundation.dart';

@immutable
class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.fullName,
    this.isAdmin = false,
  });

  final int id;
  final String email;
  final String fullName;
  final bool isAdmin;

  String get firstName {
    final trimmed = fullName.trim();
    if (trimmed.isEmpty) return 'there';
    return trimmed.split(RegExp(r'\s+')).first;
  }

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return email.isEmpty ? '?' : email[0].toUpperCase();
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'full_name': fullName,
        'is_admin': isAdmin,
      };

  /// Accepts either `role: "admin"` or `is_admin: true` from the backend.
  /// This only controls what the UI shows: the server must still enforce
  /// admin permissions on every `/admin/*` route.
  factory AppUser.fromJson(Map<String, dynamic> json) {
    final role = '${json['role'] ?? ''}'.toLowerCase();
    final flag = json['is_admin'] == true || json['is_superuser'] == true;
    return AppUser(
      id: ((json['id'] ?? 0) as num).toInt(),
      email: '${json['email'] ?? ''}',
      fullName: '${json['full_name'] ?? json['name'] ?? ''}',
      isAdmin: flag || role == 'admin' || role == 'administrator',
    );
  }
}
