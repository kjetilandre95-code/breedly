import 'package:flutter/material.dart';

Widget platformImageFromFilePath(
  String path, {
  BoxFit? fit,
}) {
  return Image.network(path, fit: fit);
}
