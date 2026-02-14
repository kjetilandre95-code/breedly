import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:breedly/services/auth_service.dart';
import 'package:breedly/utils/logger.dart';

class UserSharingService {
  static final UserSharingService _instance = UserSharingService._internal();

  factory UserSharingService() {
    return _instance;
  }

  UserSharingService._internal();

  final _firestore = FirebaseFirestore.instance;
  final _authService = AuthService();

  /// Share a breeding group with another user via email
  /// Returns the user ID of the shared user, or null if not found
  Future<String?> shareBreedingGroupWithUser(
    String breedingGroupId,
    String targetUserEmail, {
    String role = 'collaborator', // 'owner' or 'collaborator'
  }) async {
    try {
      // Find user by email
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: targetUserEmail)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        AppLogger.debug('User with email $targetUserEmail not found');
        return null;
      }

      final targetUserId = querySnapshot.docs.first.id;
      final currentUserId = _authService.currentUserId;

      if (currentUserId == null) {
        throw Exception('Current user not authenticated');
      }

      // Add user to the breeding group's shared_users collection
      await _firestore
          .collection('breeding_groups')
          .doc(breedingGroupId)
          .collection('shared_users')
          .doc(targetUserId)
          .set({
        'userId': targetUserId,
        'email': targetUserEmail,
        'role': role,
        'sharedBy': currentUserId,
        'sharedAt': FieldValue.serverTimestamp(),
        'permissions': ['read', 'write'], // Can be extended: 'delete', 'manage_sharing'
      });

      // Add to user's shared breeding groups
      await _firestore
          .collection('users')
          .doc(targetUserId)
          .collection('shared_breeding_groups')
          .doc(breedingGroupId)
          .set({
        'breedingGroupId': breedingGroupId,
        'ownerId': currentUserId,
        'role': role,
        'sharedAt': FieldValue.serverTimestamp(),
        'permissions': ['read', 'write'],
      });

      AppLogger.debug('Successfully shared breeding group with $targetUserEmail');
      return targetUserId;
    } catch (e) {
      AppLogger.debug('Error sharing breeding group: $e');
      rethrow;
    }
  }

  /// Get list of users who have access to a breeding group
  Future<List<Map<String, dynamic>>> getSharedUsersForGroup(
    String breedingGroupId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('breeding_groups')
          .doc(breedingGroupId)
          .collection('shared_users')
          .get();

      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      AppLogger.debug('Error getting shared users: $e');
      return [];
    }
  }

  /// Get list of breeding groups shared with current user
  Future<List<Map<String, dynamic>>> getSharedBreedingGroups(
    String userId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('shared_breeding_groups')
          .get();

      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      AppLogger.debug('Error getting shared breeding groups: $e');
      return [];
    }
  }

  /// Remove user access to breeding group
  Future<void> removeUserFromBreedingGroup(
    String breedingGroupId,
    String targetUserId,
  ) async {
    try {
      // Remove from group's shared_users
      await _firestore
          .collection('breeding_groups')
          .doc(breedingGroupId)
          .collection('shared_users')
          .doc(targetUserId)
          .delete();

      // Remove from user's shared_breeding_groups
      await _firestore
          .collection('users')
          .doc(targetUserId)
          .collection('shared_breeding_groups')
          .doc(breedingGroupId)
          .delete();

      AppLogger.debug('Successfully removed user from breeding group');
    } catch (e) {
      AppLogger.debug('Error removing user from breeding group: $e');
      rethrow;
    }
  }

  /// Update user role in breeding group
  Future<void> updateUserRole(
    String breedingGroupId,
    String targetUserId,
    String newRole,
  ) async {
    try {
      await _firestore
          .collection('breeding_groups')
          .doc(breedingGroupId)
          .collection('shared_users')
          .doc(targetUserId)
          .update({'role': newRole});

      await _firestore
          .collection('users')
          .doc(targetUserId)
          .collection('shared_breeding_groups')
          .doc(breedingGroupId)
          .update({'role': newRole});

      AppLogger.debug('Successfully updated user role to $newRole');
    } catch (e) {
      AppLogger.debug('Error updating user role: $e');
      rethrow;
    }
  }

  /// Check if user has access to a specific breeding group
  Future<bool> userHasAccessToGroup(
    String userId,
    String breedingGroupId,
  ) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('shared_breeding_groups')
          .doc(breedingGroupId)
          .get();

      return doc.exists;
    } catch (e) {
      AppLogger.debug('Error checking user access: $e');
      return false;
    }
  }
}
