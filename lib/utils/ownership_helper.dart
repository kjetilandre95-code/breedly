import 'package:breedly/services/kennel_service.dart';

/// Centralizes tenant ownership fields for flat Firestore collections.
class OwnershipHelper {
  static Map<String, dynamic> fieldsForUser(String userId) {
    final kennelId = KennelService().activeKennelId;
    return {
      'ownerId': userId,
      'kennelId': (kennelId != null && kennelId.isNotEmpty) ? kennelId : null,
    };
  }

  static Map<String, dynamic> mergeWithOwnership({
    required String userId,
    required Map<String, dynamic> data,
  }) {
    return {
      ...data,
      ...fieldsForUser(userId),
    };
  }
}
