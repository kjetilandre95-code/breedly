import 'package:uuid/uuid.dart';

class IdGenerator {
  static String generateId() {
    return const Uuid().v4();
  }
}
