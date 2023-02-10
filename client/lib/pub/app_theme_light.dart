import 'package:flutter/material.dart';

class AppLightTheme {
  static final _baseTheme =
      ThemeData(brightness: Brightness.light, useMaterial3: true);

  static final themeData = _baseTheme.copyWith();

  // static final themeData =
  //     ThemeData.from(colorScheme: ColorScheme.light(), useMaterial3: true);

  // static AppBarTheme buildAppBarTheme() {
  //   return AppBarTheme(
  //     centerTitle: false,
  //     foregroundColor: Colors.black,
  //     titleTextStyle: TextStyle(
  //       color: Colors.black,
  //       fontSize: 18,
  //     ),
  //   );
  // }
}
