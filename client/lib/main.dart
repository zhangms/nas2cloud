import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import 'api/api.dart';
import 'api/app_config.dart';
import 'event/bus.dart';
import 'event/event_change_theme.dart';
import 'pages/config.dart';
import 'pages/home.dart';
import 'pages/login.dart';
import 'pages/splash.dart';
import 'pages/test.dart';
import 'pub/app_theme.dark.dart';
import 'pub/app_theme_light.dart';

void main() {
  FlutterError.onError = (detail) => reportError(detail);
  runZonedGuarded(() {
    AppConfig.initialize().then((value) {
      runApp(MyApp());
    }).onError((error, stackTrace) {
      reportError(
          FlutterErrorDetails(exception: error ?? "ERROR", stack: stackTrace));
    });
  }, (error, stack) {
    reportError(FlutterErrorDetails(exception: error, stack: stack));
  });
}

void reportError(FlutterErrorDetails errorDetails) {
  final errorInfo = {
    "error": errorDetails.exceptionAsString(),
    "stack": errorDetails.stack.toString(),
  };
  print("EXCEPTION:$errorInfo");
  Api().postTraceLog("EXCEPTION:${json.encode(errorInfo)}");
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late StreamSubscription<EventChangeTheme> subscription;

  @override
  void initState() {
    super.initState();
    subscription = eventBus.on<EventChangeTheme>().listen((event) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_MyAppModel>(
        future: getMyAppModel(),
        builder: (context, snapshot) {
          _MyAppModel data = snapshot.data ?? _MyAppModel.defaultValue();
          return MaterialApp(
            title: data.appName,
            home: SplashPage(),
            theme: data.lightTheme,
            darkTheme: data.darkTheme,
            routes: <String, WidgetBuilder>{
              "/home": (_) => HomePage(),
              "/login": (_) => LoginPage(),
              "/config": (_) => ConfigPage(),
              "/test": (_) => TestPage(),
            },
          );
        });
  }

  Future<_MyAppModel> getMyAppModel() async {
    return _MyAppModel(
      appName: await AppConfig.getAppName(),
      theme: await AppConfig.getThemeSetting(),
    );
  }
}

class _MyAppModel {
  static defaultValue() {
    return _MyAppModel(
      appName: AppConfig.defaultAppName,
      theme: AppConfig.themeFollowSystem,
    );
  }

  final String appName;
  final int theme;

  _MyAppModel({required this.appName, required this.theme});

  ThemeData get darkTheme => theme == AppConfig.themeLight
      ? AppLightTheme.themeData
      : AppDarkTheme.themeData;

  ThemeData get lightTheme => theme == AppConfig.themeDark
      ? AppDarkTheme.themeData
      : AppLightTheme.themeData;
}
