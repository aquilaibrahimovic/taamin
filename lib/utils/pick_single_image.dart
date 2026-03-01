import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';

Future<File?> pickSingleImageFile() async {
  final res = await FilePicker.platform.pickFiles(
    type: FileType.image,
    allowMultiple: false,
  );
  final path = res?.files.single.path;
  if (path == null) return null;
  return File(path);
}