import 'package:flutter/material.dart';

import '../api/app_config.dart';
import 'app_message.dart';
import 'app_nav.dart';

class AppWidgets {
  static Widget pageLoadingView() {
    return Center(
      child: FutureBuilder<String>(
          future:
              Future.delayed(Duration(milliseconds: 200), () => "Loading..."),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return CircularProgressIndicator();
            }
            return Container();
          }),
    );
  }

  static Widget appBarArrowBack(BuildContext context) {
    return IconButton(
      icon: Icon(
        Icons.arrow_back,
      ),
      onPressed: () {
        AppMessage.clear(context);
        AppNav.pop(context);
      },
    );
  }

  static Widget pageEmptyView() {
    return Center(
      child: Text("Empty"),
    );
  }

  static Widget centerTextView(String text) {
    return Center(
      child: Text(text),
    );
  }

  static Widget pageErrorView(String message) {
    return Center(
      child: Text(message),
    );
  }

  static Widget repeatRotation(Widget child, int rotationDuration) {
    return RepeatRotation(child, rotationDuration);
  }

  static getAppNameText({bool? useDefault}) {
    return FutureBuilder<String>(
        future: AppConfig.getAppName(),
        builder: (context, snapshot) {
          return Text(snapshot.hasData
              ? snapshot.data!
              : (useDefault ?? false ? AppConfig.defaultAppName : ""));
        });
  }
}

class RepeatRotation extends StatefulWidget {
  final Widget child;
  final int duration;

  RepeatRotation(this.child, this.duration);

  @override
  State<RepeatRotation> createState() => _RepeatRotationState();
}

class _RepeatRotationState extends State<RepeatRotation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _repeatAniController;

  @override
  void initState() {
    super.initState();
    _repeatAniController = AnimationController(vsync: this)
      ..drive(Tween(begin: 0, end: 1))
      ..duration = Duration(milliseconds: widget.duration)
      ..repeat();
  }

  @override
  void dispose() {
    _repeatAniController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _repeatAniController,
      child: widget.child,
    );
  }
}
