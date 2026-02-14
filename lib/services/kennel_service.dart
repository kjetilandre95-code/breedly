import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:breedly/models/kennel.dart';
import 'package:breedly/models/kennel_member.dart';
import 'package:breedly/models/kennel_invitation.dart';
import 'package:breedly/services/auth_service.dart';
import 'package:breedly/utils/id_generator.dart';
import 'package:breedly/utils/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class KennelService {
  static final KennelService _instance = KennelService._internal();

  factory KennelService() {
    return _instance;
  }

  KennelService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Current active kennel ID (stored in SharedPreferences in production)
  String? _activeKennelId;
  String? get activeKennelId => _activeKennelId;

  /// Initialize kennel service and load active kennel
  Future<void> initialize() async {
    final user = AuthService().currentUser;
    if (user == null) return;

    // Try to load from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final savedKennelId = prefs.getString('active_kennel_id');
    if (savedKennelId != null) {
      _activeKennelId = savedKennelId;
    } else {
      // Try to load user's kennels
      final userKennels = await getUserKennels(user.uid);
      if (userKennels.isNotEmpty) {
        _activeKennelId = userKennels.first.id;
      }
    }
  }

  /// Set active kennel
  void setActiveKennel(String kennelId) async {
    _activeKennelId = kennelId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('active_kennel_id', kennelId);
  }

  /// Clear active kennel
  void clearActiveKennel() async {
    _activeKennelId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('active_kennel_id');
  }

  /// Generate a random 6-character invite code
  String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // No confusing chars like 0/O, 1/I
    final random = Random.secure();
    return List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();
  }

  /// Create a new kennel
  Future<Kennel> createKennel({
    required String userId,
    required String userEmail,
    required String name,
    String? description,
    String? displayName,
    List<String> breeds = const [],
  }) async {
    final kennelId = IdGenerator.generateId();
    final kennel = Kennel(
      id: kennelId,
      name: name,
      ownerId: userId,
      ownerEmail: userEmail,
      createdAt: DateTime.now(),
      description: description,
      breeds: breeds,
    );

    // Save kennel to Firestore
    await _firestore.collection('breeding_groups').doc(kennelId).set(kennel.toJson());

    // Add owner as member
    final member = KennelMember(
      userId: userId,
      kennelId: kennelId,
      email: userEmail,
      displayName: displayName,
      role: 'owner',
      joinedAt: DateTime.now(),
    );

    await _firestore
        .collection('breeding_groups')
        .doc(kennelId)
        .collection('members')
        .doc(userId)
        .set(member.toJson());

    // Add kennel reference to user
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('kennels')
        .doc(kennelId)
        .set({
      'kennelId': kennelId,
      'kennelName': name,
      'role': 'owner',
      'joinedAt': DateTime.now().toIso8601String(),
    });

    // Set as active kennel
    _activeKennelId = kennelId;

    AppLogger.debug('Kennel created: $name ($kennelId)');
    return kennel;
  }

  /// Update kennel information
  Future<void> updateKennel({
    required String kennelId,
    required String name,
    String? description,
    List<String>? breeds,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'name': name,
        'description': description,
      };

      if (breeds != null) {
        updateData['breeds'] = breeds;
      }

      await _firestore.collection('breeding_groups').doc(kennelId).update(updateData);

      // Update kennel name in all members' user references
      final membersSnapshot = await _firestore
          .collection('breeding_groups')
          .doc(kennelId)
          .collection('members')
          .get();

      for (final memberDoc in membersSnapshot.docs) {
        final userId = memberDoc.id;
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('kennels')
            .doc(kennelId)
            .update({'kennelName': name});
      }

      AppLogger.debug('Kennel updated: $name ($kennelId)');
    } catch (e) {
      AppLogger.debug('Error updating kennel: $e');
      throw Exception('Kunne ikke oppdatere kennel: $e');
    }
  }

  /// Get all kennels for current user
  Future<List<Kennel>> getUserKennels(String userId) async {
    try {
      final userKennelsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('kennels')
          .get();

      final kennels = <Kennel>[];
      for (final doc in userKennelsSnapshot.docs) {
        final kennelId = doc.data()['kennelId'] as String?;
        if (kennelId != null) {
          final kennelDoc =
              await _firestore.collection('breeding_groups').doc(kennelId).get();
          if (kennelDoc.exists) {
            kennels.add(Kennel.fromJson(kennelDoc.data()!));
          }
        }
      }
      return kennels;
    } catch (e) {
      AppLogger.debug('Error getting user kennels: $e');
      return [];
    }
  }

  /// Get current user's role in a kennel
  Future<KennelMember?> getMemberInfo(String kennelId, String userId) async {
    try {
      final doc = await _firestore
          .collection('breeding_groups')
          .doc(kennelId)
          .collection('members')
          .doc(userId)
          .get();

      if (doc.exists) {
        return KennelMember.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      AppLogger.debug('Error getting member info: $e');
      return null;
    }
  }

  /// Get all members of a kennel
  Future<List<KennelMember>> getKennelMembers(String kennelId) async {
    try {
      final snapshot = await _firestore
          .collection('breeding_groups')
          .doc(kennelId)
          .collection('members')
          .get();

      return snapshot.docs
          .map((doc) => KennelMember.fromJson(doc.data()))
          .toList();
    } catch (e) {
      AppLogger.debug('Error getting kennel members: $e');
      return [];
    }
  }

  /// Create an invitation to join a kennel
  Future<KennelInvitation> createInvitation({
    required String kennelId,
    String? invitedEmail,
    String role = 'member',
    int validDays = 7,
  }) async {
    final user = AuthService().currentUser;
    if (user == null) throw Exception('Bruker ikke innlogget');

    // Check if user has permission to invite
    final member = await getMemberInfo(kennelId, user.uid);
    if (member == null || !member.canInvite) {
      throw Exception('Du har ikke tillatelse til å invitere medlemmer');
    }

    // Get kennel name
    final kennelDoc =
        await _firestore.collection('breeding_groups').doc(kennelId).get();
    if (!kennelDoc.exists) throw Exception('Kennel ikke funnet');
    final kennelName = kennelDoc.data()?['name'] ?? 'Ukjent';

    final invitationId = IdGenerator.generateId();
    final code = _generateInviteCode();

    final invitation = KennelInvitation(
      id: invitationId,
      code: code,
      kennelId: kennelId,
      kennelName: kennelName,
      invitedByUserId: user.uid,
      invitedByEmail: user.email ?? '',
      invitedEmail: invitedEmail,
      role: role,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(Duration(days: validDays)),
    );

    // Save invitation
    await _firestore
        .collection('invitations')
        .doc(code) // Use code as doc ID for easy lookup
        .set(invitation.toJson());

    AppLogger.debug('Invitation created: $code for kennel $kennelId');
    return invitation;
  }

  /// Get invitation by code
  Future<KennelInvitation?> getInvitation(String code) async {
    try {
      final doc = await _firestore
          .collection('invitations')
          .doc(code.toUpperCase())
          .get();

      if (doc.exists) {
        return KennelInvitation.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      AppLogger.debug('Error getting invitation: $e');
      return null;
    }
  }

  /// Accept an invitation and join a kennel
  Future<void> acceptInvitation(String code) async {
    final user = AuthService().currentUser;
    if (user == null) throw Exception('Bruker ikke innlogget');

    final invitation = await getInvitation(code.toUpperCase());
    if (invitation == null) {
      throw Exception('Invitasjonskode ikke funnet');
    }

    if (!invitation.isValid) {
      if (invitation.isUsed) {
        throw Exception('Denne invitasjonskoden er allerede brukt');
      }
      if (invitation.isExpired) {
        throw Exception('Denne invitasjonskoden har utløpt');
      }
    }

    // Check if specific email was required
    if (invitation.invitedEmail != null &&
        invitation.invitedEmail!.isNotEmpty &&
        invitation.invitedEmail!.toLowerCase() != user.email?.toLowerCase()) {
      throw Exception(
          'Denne invitasjonen er kun for ${invitation.invitedEmail}');
    }

    // Check if user is already a member
    final existingMember =
        await getMemberInfo(invitation.kennelId, user.uid);
    if (existingMember != null) {
      throw Exception('Du er allerede medlem av denne kennelen');
    }

    // Add user as member
    final member = KennelMember(
      userId: user.uid,
      kennelId: invitation.kennelId,
      email: user.email ?? '',
      displayName: user.displayName,
      role: invitation.role,
      joinedAt: DateTime.now(),
      photoUrl: user.photoURL,
    );

    await _firestore
        .collection('breeding_groups')
        .doc(invitation.kennelId)
        .collection('members')
        .doc(user.uid)
        .set(member.toJson());

    // Add kennel reference to user
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('kennels')
        .doc(invitation.kennelId)
        .set({
      'kennelId': invitation.kennelId,
      'kennelName': invitation.kennelName,
      'role': invitation.role,
      'joinedAt': DateTime.now().toIso8601String(),
    });

    // Mark invitation as used
    await _firestore.collection('invitations').doc(code.toUpperCase()).update({
      'isUsed': true,
      'usedByUserId': user.uid,
      'usedAt': DateTime.now().toIso8601String(),
    });

    // Set as active kennel
    _activeKennelId = invitation.kennelId;

    AppLogger.debug('User ${user.uid} joined kennel ${invitation.kennelId}');
  }

  /// Remove a member from kennel (owner/admin only)
  Future<void> removeMember(String kennelId, String memberUserId) async {
    final user = AuthService().currentUser;
    if (user == null) throw Exception('Bruker ikke innlogget');

    // Check permissions
    final currentMember = await getMemberInfo(kennelId, user.uid);
    if (currentMember == null || !currentMember.isAdmin) {
      throw Exception('Du har ikke tillatelse til å fjerne medlemmer');
    }

    // Cannot remove owner
    final targetMember = await getMemberInfo(kennelId, memberUserId);
    if (targetMember?.isOwner ?? false) {
      throw Exception('Eieren kan ikke fjernes fra kennelen');
    }

    // Remove from kennel members
    await _firestore
        .collection('breeding_groups')
        .doc(kennelId)
        .collection('members')
        .doc(memberUserId)
        .delete();

    // Remove from user's kennels
    await _firestore
        .collection('users')
        .doc(memberUserId)
        .collection('kennels')
        .doc(kennelId)
        .delete();

    AppLogger.debug('Member $memberUserId removed from kennel $kennelId');
  }

  /// Leave a kennel
  Future<void> leaveKennel(String kennelId) async {
    final user = AuthService().currentUser;
    if (user == null) throw Exception('Bruker ikke innlogget');

    // Check if owner
    final member = await getMemberInfo(kennelId, user.uid);
    if (member?.isOwner ?? false) {
      throw Exception(
          'Eieren kan ikke forlate kennelen. Overfør eierskap eller slett kennelen.');
    }

    // Remove from kennel members
    await _firestore
        .collection('breeding_groups')
        .doc(kennelId)
        .collection('members')
        .doc(user.uid)
        .delete();

    // Remove from user's kennels
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('kennels')
        .doc(kennelId)
        .delete();

    // If this was active kennel, clear it
    if (_activeKennelId == kennelId) {
      _activeKennelId = null;
      // Load another kennel if available
      final kennels = await getUserKennels(user.uid);
      if (kennels.isNotEmpty) {
        _activeKennelId = kennels.first.id;
      }
    }

    AppLogger.debug('User ${user.uid} left kennel $kennelId');
  }

  /// Update member role (owner only)
  Future<void> updateMemberRole(
      String kennelId, String memberUserId, String newRole) async {
    final user = AuthService().currentUser;
    if (user == null) throw Exception('Bruker ikke innlogget');

    // Only owner can change roles
    final currentMember = await getMemberInfo(kennelId, user.uid);
    if (currentMember == null || !currentMember.isOwner) {
      throw Exception('Kun eieren kan endre roller');
    }

    // Cannot change owner role
    if (memberUserId == user.uid) {
      throw Exception('Du kan ikke endre din egen rolle som eier');
    }

    // Update role
    await _firestore
        .collection('breeding_groups')
        .doc(kennelId)
        .collection('members')
        .doc(memberUserId)
        .update({'role': newRole});

    // Update user's kennel reference
    await _firestore
        .collection('users')
        .doc(memberUserId)
        .collection('kennels')
        .doc(kennelId)
        .update({'role': newRole});

    AppLogger.debug('Member $memberUserId role updated to $newRole in kennel $kennelId');
  }

  /// Delete kennel (owner only)
  Future<void> deleteKennel(String kennelId) async {
    final user = AuthService().currentUser;
    if (user == null) throw Exception('Bruker ikke innlogget');

    // Only owner can delete
    final member = await getMemberInfo(kennelId, user.uid);
    if (member == null || !member.isOwner) {
      throw Exception('Kun eieren kan slette kennelen');
    }

    // Get all members first
    final members = await getKennelMembers(kennelId);

    // Remove kennel reference from all members
    for (final m in members) {
      await _firestore
          .collection('users')
          .doc(m.userId)
          .collection('kennels')
          .doc(kennelId)
          .delete();
    }

    // Delete all subcollections (members)
    final membersSnapshot = await _firestore
        .collection('breeding_groups')
        .doc(kennelId)
        .collection('members')
        .get();
    for (final doc in membersSnapshot.docs) {
      await doc.reference.delete();
    }

    // Delete the kennel document
    await _firestore.collection('breeding_groups').doc(kennelId).delete();

    // Clear active kennel
    if (_activeKennelId == kennelId) {
      _activeKennelId = null;
    }

    AppLogger.debug('Kennel $kennelId deleted');
  }

  /// Get active invitations for a kennel
  Future<List<KennelInvitation>> getActiveInvitations(String kennelId) async {
    try {
      final snapshot = await _firestore
          .collection('invitations')
          .where('kennelId', isEqualTo: kennelId)
          .where('isUsed', isEqualTo: false)
          .get();

      return snapshot.docs
          .map((doc) => KennelInvitation.fromJson(doc.data()))
          .where((inv) => !inv.isExpired)
          .toList();
    } catch (e) {
      AppLogger.debug('Error getting active invitations: $e');
      return [];
    }
  }

  /// Delete an invitation
  Future<void> deleteInvitation(String code) async {
    await _firestore.collection('invitations').doc(code).delete();
  }

  /// Check if user has any kennels
  Future<bool> userHasKennels(String userId) async {
    final kennels = await getUserKennels(userId);
    return kennels.isNotEmpty;
  }

  /// Migrate existing user data to a new kennel
  /// This moves data from users/{userId}/ to kennels/{kennelId}/
  Future<void> migrateUserDataToKennel(String userId, String kennelId) async {
    AppLogger.debug('Starting migration of user $userId data to kennel $kennelId');

    final batch = _firestore.batch();

    // Migrate dogs
    final dogsSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('dogs')
        .get();

    for (final doc in dogsSnapshot.docs) {
      final newRef =
          _firestore.collection('breeding_groups').doc(kennelId).collection('dogs').doc(doc.id);
      batch.set(newRef, doc.data());
    }

    // Migrate litters and their puppies
    final littersSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('litters')
        .get();

    for (final litterDoc in littersSnapshot.docs) {
      final newLitterRef = _firestore
          .collection('breeding_groups')
          .doc(kennelId)
          .collection('litters')
          .doc(litterDoc.id);
      batch.set(newLitterRef, litterDoc.data());

      // Migrate puppies for this litter
      final puppiesSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('litters')
          .doc(litterDoc.id)
          .collection('puppies')
          .get();

      for (final puppyDoc in puppiesSnapshot.docs) {
        final newPuppyRef = newLitterRef.collection('puppies').doc(puppyDoc.id);
        batch.set(newPuppyRef, puppyDoc.data());
      }
    }

    // Migrate buyers
    final buyersSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('buyers')
        .get();

    for (final doc in buyersSnapshot.docs) {
      final newRef = _firestore
          .collection('breeding_groups')
          .doc(kennelId)
          .collection('buyers')
          .doc(doc.id);
      batch.set(newRef, doc.data());
    }

    // Migrate expenses
    final expensesSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('expenses')
        .get();

    for (final doc in expensesSnapshot.docs) {
      final newRef = _firestore
          .collection('breeding_groups')
          .doc(kennelId)
          .collection('expenses')
          .doc(doc.id);
      batch.set(newRef, doc.data());
    }

    // Migrate income
    final incomeSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('income')
        .get();

    for (final doc in incomeSnapshot.docs) {
      final newRef = _firestore
          .collection('breeding_groups')
          .doc(kennelId)
          .collection('income')
          .doc(doc.id);
      batch.set(newRef, doc.data());
    }

    // Commit all migrations
    await batch.commit();

    AppLogger.debug('Migration completed for user $userId to kennel $kennelId');
  }
}
