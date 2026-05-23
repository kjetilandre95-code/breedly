import 'package:flutter/material.dart';

Widget imageFromFilePath(
  String path, {
  BoxFit? fit,
  double? width,
  double? height,
}) {
  return Image.network(path, fit: fit, width: width, height: height);
}
