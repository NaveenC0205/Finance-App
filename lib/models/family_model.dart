class FamilyModel {
  final String id;
  final String name;
  final String adminClerkId;
  final String inviteCode;
  final DateTime createdAt;

  FamilyModel({
    required this.id,
    required this.name,
    required this.adminClerkId,
    required this.inviteCode,
    required this.createdAt,
  });

  factory FamilyModel.fromJson(Map<String, dynamic> json) => FamilyModel(
        id: json['id'],
        name: json['name'],
        adminClerkId: json['admin_clerk_id'],
        inviteCode: json['invite_code'],
        createdAt: DateTime.parse(json['created_at']),
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'admin_clerk_id': adminClerkId,
        'invite_code': inviteCode,
      };
}

class FamilyMemberModel {
  final String id;
  final String familyId;
  final String clerkUserId;
  final String email;
  final String name;
  final String? picture;
  final String role;
  final DateTime joinedAt;

  FamilyMemberModel({
    required this.id,
    required this.familyId,
    required this.clerkUserId,
    required this.email,
    required this.name,
    this.picture,
    required this.role,
    required this.joinedAt,
  });

  bool get isAdmin => role == 'admin';

  factory FamilyMemberModel.fromJson(Map<String, dynamic> json) => FamilyMemberModel(
        id: json['id'],
        familyId: json['family_id'],
        clerkUserId: json['clerk_user_id'],
        email: json['email'],
        name: json['name'],
        picture: json['picture'],
        role: json['role'],
        joinedAt: DateTime.parse(json['joined_at']),
      );
}
