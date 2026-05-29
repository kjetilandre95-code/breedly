import 'dart:io';

import 'package:flutter/material.dart';

Widget platformImageFromFilePath(
  String path, {
  BoxFit? fit,
}) {
  if (path.startsWith('http://') || path.startsWith('https://')) {
    return Image.network(path, fit: fit);
  }
  return Image.file(File(path), fit: fit);
}
