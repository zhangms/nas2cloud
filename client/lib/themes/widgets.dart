import 'package:flutter/material.dart';

class AppWidgets {
  static Widget getPageLoadingView() {
    return Center(
      child: FutureBuilder<String>(
          future:
              Future.delayed(Duration(milliseconds: 200), () => "Loading..."),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Text(snapshot.data ?? "");
            }
            return Text("");
          }),
    );
  }

  static Widget getPageEmptyView() {
    return Center(
      child: Text("Empty"),
    );
  }

  static Widget getCenterTextView(String text) {
    return Center(
      child: Text(text),
    );
  }

  static Widget getPageErrorView(String message) {
    return Center(
      child: Text(message),
    );
  }
}
