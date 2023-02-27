import 'dart:math';

import 'package:flutter/material.dart';

const _horizontalPadding = 24.0;

double screenMainAreaWidth({required BuildContext context}) {
  return min(
    360,
    MediaQuery.of(context).size.width - 2 * _horizontalPadding,
  );
}

double screenWidth({required BuildContext context}) {
  return MediaQuery.of(context).size.width;
}
