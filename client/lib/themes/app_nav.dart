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

  static open(BuildContext context, Widget widget) {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => widget));
  }

  static Future<void> popAll(BuildContext context) async {
    var nav = Navigator.of(context);
    while (await nav.maybePop()) {
      nav.pop();
    }
  }
}
