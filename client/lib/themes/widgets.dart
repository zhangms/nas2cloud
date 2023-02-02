import 'package:flutter/material.dart';
import 'package:nas2cloud/api/app_config.dart';

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

  static Widget getRepeatRotation(Widget child, int rotationDuration) {
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
  final int rotationDuration;

  RepeatRotation(this.child, this.rotationDuration);

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
      ..duration = Duration(milliseconds: widget.rotationDuration)
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
