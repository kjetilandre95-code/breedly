import 'package:hive/hive.dart';

part 'kennel_member.g.dart';

/// Roles for kennel members
enum KennelRole {
  owner,  // Full access, can delete kennel and manage all members
  admin,  // Can add/edit data and invite new members
  member, // Can add/edit data but cannot invite
}

@HiveType(typeId: 21)
class KennelMember extends HiveObject {
  @HiveField(0)
  String userId;

  @HiveField(1)
  String kennelId;

  @HiveField(2)
  String email;

  @HiveField(3)
  String? displayName;

  @HiveField(4)
  String role; // 'owner', 'admin', 'member'

  @HiveField(5)
  DateTime joinedAt;

  @HiveField(6)
  String? photoUrl;

  KennelMember({
    required this.userId,
    required this.kennelId,
    required this.email,
    this.displayName,
    required this.role,
    required this.joinedAt,
    this.photoUrl,
  });

  KennelRole get kennelRole {
    switch (role) {
      case 'owner':
        return KennelRole.owner;
      case 'admin':
        return KennelRole.admin;
      default:
        return KennelRole.member;
    }
  }

  bool get isOwner => role == 'owner';
  bool get isAdmin => role == 'owner' || role == 'admin';
  bool get canInvite => role == 'owner' || role == 'admin';

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'kennelId': kennelId,
      'email': email,
      'displayName': displayName,
      'role': role,
      'joinedAt': joinedAt.toIso8601String(),
      'photoUrl': photoUrl,
    };
  }

  factory KennelMember.fromJson(Map<String, dynamic> json) {
    return KennelMember(
      userId: json['userId'] ?? '',
      kennelId: json['kennelId'] ?? '',
      email: json['email'] ?? '',
      displayName: json['displayName'],
      role: json['role'] ?? 'member',
      joinedAt: json['joinedAt'] != null
          ? DateTime.parse(json['joinedAt'])
          : DateTime.now(),
      photoUrl: json['photoUrl'],
    );
  }
}
