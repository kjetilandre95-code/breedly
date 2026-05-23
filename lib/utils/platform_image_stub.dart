import 'dart:io';

import 'package:flutter/material.dart';

Widget imageFromFilePath(
  String path, {
  BoxFit? fit,
  double? width,
  double? height,
}) {
  return Image.file(File(path), fit: fit, width: width, height: height);
}
