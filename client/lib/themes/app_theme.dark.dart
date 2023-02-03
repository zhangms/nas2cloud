import 'package:flutter/material.dart';

class AppDarkTheme {
  static final _baseTheme =
      ThemeData(brightness: Brightness.dark, useMaterial3: true);

  static final themeData = _baseTheme.copyWith();
}
