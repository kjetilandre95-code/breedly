import 'package:hive/hive.dart';

part 'kennel_invitation.g.dart';

@HiveType(typeId: 22)
class KennelInvitation extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String code; // 6-character invite code

  @HiveField(2)
  String kennelId;

  @HiveField(3)
  String kennelName;

  @HiveField(4)
  String invitedByUserId;

  @HiveField(5)
  String invitedByEmail;

  @HiveField(6)
  String? invitedEmail; // Optional: specific email to invite

  @HiveField(7)
  String role; // Role to assign when accepted: 'admin' or 'member'

  @HiveField(8)
  DateTime createdAt;

  @HiveField(9)
  DateTime expiresAt;

  @HiveField(10)
  bool isUsed;

  @HiveField(11)
  String? usedByUserId;

  @HiveField(12)
  DateTime? usedAt;

  KennelInvitation({
    required this.id,
    required this.code,
    required this.kennelId,
    required this.kennelName,
    required this.invitedByUserId,
    required this.invitedByEmail,
    this.invitedEmail,
    required this.role,
    required this.createdAt,
    required this.expiresAt,
    this.isUsed = false,
    this.usedByUserId,
    this.usedAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isValid => !isUsed && !isExpired;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'kennelId': kennelId,
      'kennelName': kennelName,
      'invitedByUserId': invitedByUserId,
      'invitedByEmail': invitedByEmail,
      'invitedEmail': invitedEmail,
      'role': role,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'isUsed': isUsed,
      'usedByUserId': usedByUserId,
      'usedAt': usedAt?.toIso8601String(),
    };
  }

  factory KennelInvitation.fromJson(Map<String, dynamic> json) {
    return KennelInvitation(
      id: json['id'] ?? '',
      code: json['code'] ?? '',
      kennelId: json['kennelId'] ?? '',
      kennelName: json['kennelName'] ?? '',
      invitedByUserId: json['invitedByUserId'] ?? '',
      invitedByEmail: json['invitedByEmail'] ?? '',
      invitedEmail: json['invitedEmail'],
      role: json['role'] ?? 'member',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'])
          : DateTime.now().add(const Duration(days: 7)),
      isUsed: json['isUsed'] ?? false,
      usedByUserId: json['usedByUserId'],
      usedAt: json['usedAt'] != null ? DateTime.parse(json['usedAt']) : null,
    );
  }
}
