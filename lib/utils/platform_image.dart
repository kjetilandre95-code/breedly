import 'package:flutter/material.dart';

import 'platform_image_stub.dart'
    if (dart.library.io) 'platform_image_io.dart';

Widget imageFromFilePath(
  String path, {
  BoxFit? fit,
}) {
  return platformImageFromFilePath(path, fit: fit);
}
