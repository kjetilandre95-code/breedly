import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

Widget imageFromFilePath(String path, {BoxFit? fit}) {
  if (kIsWeb) {
    return Image.network(path, fit: fit);
  }
  return Image.file(File(path), fit: fit);
}
