import 'dart:typed_data';

import 'package:flutter/foundation.dart';

void downloadBytes(Uint8List bytes, String fileName) {
  debugPrint('Web download requested for $fileName (${bytes.length} bytes)');
}
