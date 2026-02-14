import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:breedly/models/kennel.dart';
import 'package:breedly/models/kennel_member.dart';
import 'package:breedly/services/kennel_service.dart';

class KennelProvider extends ChangeNotifier {
  static const String _boxName = 'kennel_settings';
  static const String _activeKennelKey = 'active_kennel_id';

  final KennelService _kennelService = KennelService();

  List<Kennel> _kennels = [];
  Kennel? _activeKennel;
  KennelMember? _currentMembership;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Kennel> get kennels => _kennels;
  Kennel? get activeKennel => _activeKennel;
  KennelMember? get currentMembership => _currentMembership;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasActiveKennel => _activeKennel != null;
  
  /// Check if current user is owner of active kennel
  bool get isOwner => _currentMembership?.isOwner ?? false;
  
  /// Check if current user is admin of active kennel
  bool get isAdmin => _currentMembership?.isAdmin ?? false;
  
  /// Check if current user can invite members
  bool get canInvite => _currentMembership?.canInvite ?? false;

  /// Initialize provider with user's kennels
  Future<void> initialize(String userId, String userEmail) async {
    _setLoading(true);
    _error = null;

    try {
      // Load kennels for user
      await loadKennels(userId);

      // Restore active kennel from local storage
      await _restoreActiveKennel(userId, userEmail);
    } catch (e) {
      _error = 'Feil ved initialisering av kennel: $e';
      debugPrint(_error);
    } finally {
      _setLoading(false);
    }
  }

  /// Load all kennels for user
  Future<void> loadKennels(String userId) async {
    try {
      _kennels = await _kennelService.getUserKennels(userId);
      notifyListeners();
    } catch (e) {
      _error = 'Feil ved lasting av kenneler: $e';
      debugPrint(_error);
      rethrow;
    }
  }

  /// Create a new kennel and set it as active
  Future<Kennel?> createKennel({
    required String userId,
    required String userEmail,
    required String name,
    String? description,
    String? displayName,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      final kennel = await _kennelService.createKennel(
        userId: userId,
        userEmail: userEmail,
        name: name,
        description: description,
        displayName: displayName,
      );

      // Reload kennels
      await loadKennels(userId);

      // Set as active
      await setActiveKennel(kennel.id, userId, userEmail);

      return kennel;
    } catch (e) {
      _error = 'Feil ved opprettelse av kennel: $e';
      debugPrint(_error);
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Set active kennel
  Future<void> setActiveKennel(String kennelId, String userId, String userEmail) async {
    _setLoading(true);
    _error = null;

    try {
      // Find kennel in list
      final kennel = _kennels.firstWhere(
        (k) => k.id == kennelId,
        orElse: () => throw Exception('Kennel ikke funnet'),
      );

      // Get membership info
      final membership = await _kennelService.getMemberInfo(kennelId, userId);
      
      _activeKennel = kennel;
      _currentMembership = membership;

      // Update KennelService
      _kennelService.setActiveKennel(kennelId);

      // Save to local storage
      await _saveActiveKennelToStorage(kennelId);

      notifyListeners();
    } catch (e) {
      _error = 'Feil ved setting av aktiv kennel: $e';
      debugPrint(_error);
    } finally {
      _setLoading(false);
    }
  }

  /// Clear active kennel (switch to personal mode)
  Future<void> clearActiveKennel() async {
    _activeKennel = null;
    _currentMembership = null;
    _kennelService.clearActiveKennel();
    await _clearActiveKennelFromStorage();
    notifyListeners();
  }

  /// Accept an invitation
  Future<bool> acceptInvitation({
    required String inviteCode,
    required String userId,
    required String userEmail,
    String? displayName,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      // acceptInvitation uses AuthService internally for user info
      await _kennelService.acceptInvitation(inviteCode);

      // Reload kennels to include the new one
      await loadKennels(userId);

      return true;
    } catch (e) {
      _error = 'Feil ved godkjenning av invitasjon: $e';
      debugPrint(_error);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Leave the active kennel
  Future<bool> leaveActiveKennel(String userId) async {
    if (_activeKennel == null) return false;

    _setLoading(true);
    _error = null;

    try {
      // leaveKennel uses AuthService internally for user info
      await _kennelService.leaveKennel(_activeKennel!.id);

      // Clear active kennel
      await clearActiveKennel();
      // Reload kennels
      await loadKennels(userId);

      return true;
    } catch (e) {
      _error = 'Feil ved forlating av kennel: $e';
      debugPrint(_error);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Delete the active kennel (owner only)
  Future<bool> deleteActiveKennel(String userId) async {
    if (_activeKennel == null || !isOwner) return false;

    _setLoading(true);
    _error = null;

    try {
      // deleteKennel uses AuthService internally for user info
      await _kennelService.deleteKennel(_activeKennel!.id);

      // Clear active kennel
      await clearActiveKennel();
      // Reload kennels
      await loadKennels(userId);

      return true;
    } catch (e) {
      _error = 'Feil ved sletting av kennel: $e';
      debugPrint(_error);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Migrate existing user data to a new kennel
  Future<bool> migrateDataToKennel(String userId) async {
    if (_activeKennel == null) return false;

    _setLoading(true);
    _error = null;

    try {
      await _kennelService.migrateUserDataToKennel(userId, _activeKennel!.id);
      return true;
    } catch (e) {
      _error = 'Feil ved migrering av data: $e';
      debugPrint(_error);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ============ Private helpers ============

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  Future<void> _restoreActiveKennel(String userId, String userEmail) async {
    try {
      final box = await Hive.openBox(_boxName);
      final savedKennelId = box.get(_activeKennelKey) as String?;

      if (savedKennelId != null && _kennels.any((k) => k.id == savedKennelId)) {
        await setActiveKennel(savedKennelId, userId, userEmail);
      }
    } catch (e) {
      debugPrint('Feil ved gjenoppretting av aktiv kennel: $e');
    }
  }

  Future<void> _saveActiveKennelToStorage(String kennelId) async {
    try {
      final box = await Hive.openBox(_boxName);
      await box.put(_activeKennelKey, kennelId);
    } catch (e) {
      debugPrint('Feil ved lagring av aktiv kennel: $e');
    }
  }

  Future<void> _clearActiveKennelFromStorage() async {
    try {
      final box = await Hive.openBox(_boxName);
      await box.delete(_activeKennelKey);
    } catch (e) {
      debugPrint('Feil ved sletting av aktiv kennel: $e');
    }
  }

  /// Clear all state (for logout)
  void clear() {
    _kennels = [];
    _activeKennel = null;
    _currentMembership = null;
    _error = null;
    _kennelService.clearActiveKennel();
    notifyListeners();
  }
}
