import 'package:flutter/widgets.dart';

Widget buildReceiptImageImpl(
  String path, {
  double? height,
  BoxFit? fit,
}) {
  return Image.network(path, height: height, fit: fit);
}
