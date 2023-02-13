import 'package:flutter/material.dart';

class AppMessage {
  static void clear(BuildContext context) {
    ScaffoldMessenger.of(context).clearSnackBars();
  }

  static void show(BuildContext context, String message) {
    clear(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
    ));
  }
}
