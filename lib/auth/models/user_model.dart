class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String role;
  final String? avatarUrl;
  final int totalScore;
  final int level;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.avatarUrl,
    required this.totalScore,
    required this.level,
  });

  // Convert from JSON (Supabase response)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String,
      role: json['role'] as String,
      avatarUrl: json['avatar_url'] as String?,
      totalScore: json['total_score'] as int? ?? 0,
      level: json['level'] as int? ?? 1,
    );
  }

  // Convert to JSON (for Supabase insert/update)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'role': role,
      'avatar_url': avatarUrl,
      'total_score': totalScore,
      'level': level,
    };
  }

  // Copy with method for immutability
  UserModel copyWith({
    String? id,
    String? email,
    String? fullName,
    String? role,
    String? avatarUrl,
    int? totalScore,
    int? level,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      totalScore: totalScore ?? this.totalScore,
      level: level ?? this.level,
    );
  }

  @override
  String toString() =>
      'UserModel(id: $id, email: $email, fullName: $fullName, role: $role, avatarUrl: $avatarUrl, totalScore: $totalScore, level: $level)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email &&
          fullName == other.fullName &&
          role == other.role &&
          avatarUrl == other.avatarUrl &&
          totalScore == other.totalScore &&
          level == other.level;

  @override
  int get hashCode =>
      id.hashCode ^
      email.hashCode ^
      fullName.hashCode ^
      role.hashCode ^
      avatarUrl.hashCode ^
      totalScore.hashCode ^
      level.hashCode;
}
