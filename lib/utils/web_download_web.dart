import 'dart:convert';
import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void downloadBytes(Uint8List bytes, String fileName) {
  final encoded = base64Encode(bytes);
  final anchor = html.AnchorElement(
    href: 'data:application/octet-stream;base64,$encoded',
  )
    ..download = fileName
    ..style.display = 'none';
  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
}
