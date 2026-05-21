import 'package:breedly/services/kennel_service.dart';

/// Shared ownership metadata for flat Firestore collections.
class OwnershipHelper {
  const OwnershipHelper._();

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
    final payload = <String, dynamic>{
      ...data,
      ...fieldsForUser(userId),
    };
    payload.putIfAbsent('isDeleted', () => false);
    return payload;
  }
}
