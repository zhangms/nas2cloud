import 'package:flutter/material.dart';

class AppWidgets {
  static Widget getPageLoadingView() {
    return Center(
      child: Text("Loading..."),
    );
  }

  static Widget getPageEmptyView() {
    return Center(
      child: Text("Empty"),
    );
  }

  static Widget getPageErrorView(String message) {
    return Center(
      child: Text(message),
    );
  }
}
