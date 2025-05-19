import 'package:flutter/material.dart';

Widget withOrientationSupport({
  required BuildContext context,
  required Widget portrait,
  required Widget landscape,
}) {
  return OrientationBuilder(
    builder: (context, orientation) {
      return orientation == Orientation.portrait ? portrait : landscape;
    },
  );
}