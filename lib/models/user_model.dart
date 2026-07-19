enum UserRole { superAdmin, admin, electionOfficial }
enum AccountStatus { pending, approved, suspended }

class UserAccount {
  final String id;
  final String firstName;
  final String surname;
  final String email;
  final UserRole role;
  final AccountStatus status;
  final String? rank;
  final DateTime createdAt;
  final String? photoUrl;
  final bool isDeleted;
  final DateTime? lastSeen;
  final Set<String> enabledPermissions;

  UserAccount({
    required this.id,
    required this.firstName,
    required this.surname,
    required this.email,
    required this.role,
    this.status = AccountStatus.pending,
    this.rank,
    DateTime? createdAt,
    this.photoUrl,
    this.isDeleted = false,
    this.lastSeen,
    this.enabledPermissions = const {'/admin'},
  }) : createdAt = createdAt ?? DateTime.now();

  factory UserAccount.fromJson(Map<String, dynamic> json) {
    UserRole safeRole(String? name) {
      if (name == null) return UserRole.admin;
      try {
        return UserRole.values.byName(name.trim());
      } catch (_) {
        if (name.contains('super')) return UserRole.superAdmin;
        return UserRole.admin;
      }
    }

    AccountStatus safeStatus(String? name) {
      if (name == null) return AccountStatus.pending;
      try {
        return AccountStatus.values.byName(name.trim());
      } catch (_) {
        return AccountStatus.approved;
      }
    }

    return UserAccount(
      id: json['id']?.toString() ?? '',
      firstName: json['first_name']?.toString() ?? 'Unknown',
      surname: json['surname']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: safeRole(json['role']?.toString()),
      status: safeStatus(json['status']?.toString()),
      rank: json['rank']?.toString(),
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'].toString()) : DateTime.now(),
      photoUrl: json['photo_url']?.toString(),
      isDeleted: json['is_deleted'] == true,
      lastSeen: json['last_seen'] != null ? DateTime.parse(json['last_seen'].toString()) : null,
      enabledPermissions: Set<String>.from((json['enabled_permissions'] as List? ?? []).map((e) => e.toString())),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'surname': surname,
      'email': email,
      'role': role.name,
      'status': status.name,
      'rank': rank,
      'created_at': createdAt.toIso8601String(),
      'photo_url': photoUrl,
      'is_deleted': isDeleted,
      'last_seen': lastSeen?.toIso8601String(),
      'enabled_permissions': enabledPermissions.toList(),
    };
  }

  String get name => "$firstName $surname";

  UserAccount copyWith({
    String? firstName,
    String? surname,
    String? email,
    UserRole? role,
    AccountStatus? status,
    String? rank,
    bool? isDeleted,
    DateTime? lastSeen,
    Set<String>? enabledPermissions,
    String? photoUrl,
  }) {
    return UserAccount(
      id: id,
      firstName: firstName ?? this.firstName,
      surname: surname ?? this.surname,
      email: email ?? this.email,
      role: role ?? this.role,
      status: status ?? this.status,
      rank: rank ?? this.rank,
      createdAt: createdAt,
      photoUrl: photoUrl ?? this.photoUrl,
      isDeleted: isDeleted ?? this.isDeleted,
      lastSeen: lastSeen ?? this.lastSeen,
      enabledPermissions: enabledPermissions ?? this.enabledPermissions,
    );
  }

  UserRole get activePrimaryRole => role;
  Set<UserRole> get activeRoles => {role};
}
