import 'package:flutter/widgets.dart';

Widget imageFromFilePath(String path, {BoxFit? fit}) {
  return Image.network(path, fit: fit);
}
