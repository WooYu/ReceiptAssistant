import 'package:flutter/widgets.dart';

import 'receipt_image_stub.dart'
    if (dart.library.io) 'receipt_image_io.dart';

Widget buildReceiptImage(
  String path, {
  double? height,
  BoxFit? fit,
}) {
  return buildReceiptImageImpl(path, height: height, fit: fit);
}
