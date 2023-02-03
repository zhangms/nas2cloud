import 'package:flutter/material.dart';

class AppNav {
  static gohome(BuildContext context) async {
    var nav = Navigator.of(context);
    await popAll(context);
    nav.pushReplacementNamed("/home");
  }

  static goLogin(BuildContext context) async {
    var nav = Navigator.of(context);
    await popAll(context);
    nav.pushReplacementNamed("/login");
  }

  static goServerAddressConfig(BuildContext context) async {
    var nav = Navigator.of(context);
    await popAll(context);
    nav.pushReplacementNamed("/config");
  }

  static goTest(BuildContext context) async {
    var nav = Navigator.of(context);
    await popAll(context);
    nav.pushReplacementNamed("/test");
  }

  static pop(BuildContext context) {
    Navigator.of(context).pop();
  }

  static openPage(BuildContext context, Widget widget) {
    Navigator.of(context).push(PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => widget,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        const curve = Curves.ease;
        var tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    ));
  }

  static Future<void> popAll(BuildContext context) async {
    var nav = Navigator.of(context);
    while (await nav.maybePop()) {
      nav.pop();
    }
  }
}
