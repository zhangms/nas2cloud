import 'package:flutter/material.dart';

class AppLightTheme {
  static final themeData = ThemeData(
      primarySwatch: Colors.blue,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 16,
        ),
      ));
}
