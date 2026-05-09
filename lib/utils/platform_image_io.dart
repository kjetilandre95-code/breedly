import 'dart:io';

import 'package:flutter/widgets.dart';

Widget imageFromFilePath(String path, {BoxFit? fit}) {
  return Image.file(File(path), fit: fit);
}
