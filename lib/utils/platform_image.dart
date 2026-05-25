import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

Widget imageFromFilePath(
  String path, {
  BoxFit? fit,
  double? width,
  double? height,
}) {
  if (kIsWeb) {
    return Image.network(
      path,
      fit: fit,
      width: width,
      height: height,
    );
  }

  return Image.file(
    File(path),
    fit: fit,
    width: width,
    height: height,
  );
}
