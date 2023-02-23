import 'package:flutter/material.dart';

abstract class ClipboardDataBase {
  const ClipboardDataBase();

  String buildMessage(BuildContext context);
}

class TextData extends ClipboardDataBase {
  const TextData(this.text);

  final String text;

  @override
  String buildMessage(BuildContext context) {
    return text;
  }
}

class FileData extends ClipboardDataBase {
  const FileData(this.uri);

  final Uri uri;

  @override
  String buildMessage(BuildContext context) {
    return uri.toFilePath();
  }
}
