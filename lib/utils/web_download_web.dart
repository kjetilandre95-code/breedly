import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';

void downloadBytes(Uint8List bytes, String fileName) {
  final content = base64Encode(bytes);
  final anchor = html.AnchorElement(
    href: 'data:application/octet-stream;base64,$content',
  )
    ..download = fileName
    ..style.display = 'none';
  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
}
