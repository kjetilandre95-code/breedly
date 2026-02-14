import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:breedly/utils/logger.dart';
import 'package:breedly/services/data_sync_service.dart';
import 'package:breedly/services/auth_service.dart';

class OfflineModeManager {
  static final OfflineModeManager _instance = OfflineModeManager._internal();

  factory OfflineModeManager() {
    return _instance;
  }

  OfflineModeManager._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription? _connectivitySubscription;
  
  bool _isOnline = true;
  final List<Map<String, dynamic>> _pendingOperations = [];

  // Stream controllers
  final _onlineStatusController = StreamController<bool>.broadcast();
  final _pendingOperationsController =
      StreamController<List<Map<String, dynamic>>>.broadcast();

  /// Helper to check if connectivity result indicates online
  bool _isConnected(dynamic result) {
    try {
      if (result is List) {
        // connectivity_plus 6.x+ returns List<ConnectivityResult>
        for (final r in result) {
          if (r != ConnectivityResult.none) return true;
        }
        return result.isNotEmpty && !result.contains(ConnectivityResult.none);
      } else if (result is ConnectivityResult) {
        return result != ConnectivityResult.none;
      }
      return true; // Default to online if we can't determine
    } catch (e) {
      debugPrint('Error checking connectivity result: $e');
      return true; // Default to online
    }
  }

  /// Initialize offline mode manager
  Future<void> initialize() async {
    try {
      // Check initial connectivity
      final result = await _connectivity.checkConnectivity();
      _isOnline = _isConnected(result);

      // Listen to connectivity changes
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        (dynamic result) {
          final wasOnline = _isOnline;
          _isOnline = _isConnected(result);

          if (wasOnline != _isOnline) {
            _onlineStatusController.add(_isOnline);

            if (_isOnline) {
              // Device came online - process pending operations
              _processPendingOperations();
            }
          }
        },
      );
    } catch (e) {
      debugPrint('Error initializing offline mode: $e');
      _isOnline = true; // Default to online to allow Firebase operations
    }
  }

  /// Check if device is online
  bool get isOnline => _isOnline;

  /// Get online status stream
  Stream<bool> get onlineStatusStream => _onlineStatusController.stream;

  /// Get pending operations stream
  Stream<List<Map<String, dynamic>>> get pendingOperationsStream =>
      _pendingOperationsController.stream;

  /// Get pending operations
  List<Map<String, dynamic>> get pendingOperations => _pendingOperations;

  /// Add pending operation
  void addPendingOperation({
    required String id,
    required String type, // 'create', 'update', 'delete'
    required String collection, // 'dogs', 'litters', 'puppies', etc.
    required Map<String, dynamic> data,
    required DateTime timestamp,
  }) {
    if (_isOnline) {
      // If online, execute immediately (should not happen if checked before)
      return;
    }

    _pendingOperations.add({
      'id': id,
      'type': type,
      'collection': collection,
      'data': data,
      'timestamp': timestamp,
      'retries': 0,
      'maxRetries': 3,
    });

    _pendingOperationsController.add(_pendingOperations);
    AppLogger.debug('Added pending operation: $id ($type)');
  }

  /// Process all pending operations
  Future<void> _processPendingOperations() async {
    if (_pendingOperations.isEmpty) return;

    AppLogger.debug('Processing ${_pendingOperations.length} pending operations...');

    // Instead of processing individual operations, perform a full sync
    // This is more reliable and covers all data types
    try {
      final authService = AuthService();
      if (authService.isAuthenticated && authService.currentUserId != null) {
        final dataSyncService = DataSyncService();
        await dataSyncService.performFullSync(authService.currentUserId!);
        AppLogger.debug('Successfully performed full sync after coming online');
      }
    } catch (e) {
      AppLogger.debug('Error during full sync: $e');
    }

    // Clear all pending operations after sync attempt
    _pendingOperations.clear();
    _pendingOperationsController.add(_pendingOperations);
  }

  /// Retry failed operation
  Future<void> retrySyncOperation(String operationId) async {
    final operation =
        _pendingOperations.firstWhere((op) => op['id'] == operationId, orElse: () => {});

    if (operation.isNotEmpty) {
      operation['retries'] = 0; // Reset retries
      if (_isOnline) {
        await _processPendingOperations();
      }
    }
  }

  /// Manually trigger sync
  Future<void> manualSync() async {
    if (_isOnline) {
      await _processPendingOperations();
    }
  }

  /// Clear all pending operations
  void clearPendingOperations() {
    _pendingOperations.clear();
    _pendingOperationsController.add(_pendingOperations);
  }

  /// Check if operation is pending
  bool isOperationPending(String operationId) {
    return _pendingOperations.any((op) => op['id'] == operationId);
  }

  /// Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _onlineStatusController.close();
    _pendingOperationsController.close();
  }
}
