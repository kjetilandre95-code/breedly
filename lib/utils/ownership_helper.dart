import 'package:breedly/services/kennel_service.dart';

/// Builds the tenant ownership fields used by flat Firestore collections.
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
    return {
      ...data,
      ...fieldsForUser(userId),
      'isDeleted': data['isDeleted'] ?? false,
    };
  }
}
