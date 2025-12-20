import 'dart:io';

import 'package:flutter/widgets.dart';

Widget buildReceiptImageImpl(
  String path, {
  double? height,
  BoxFit? fit,
}) {
  return Image.file(File(path), height: height, fit: fit);
}
