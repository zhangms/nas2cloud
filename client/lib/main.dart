import 'package:flutter/material.dart';
import 'package:nas2cloud/api/app_config.dart';
import 'package:nas2cloud/event/event_change_theme.dart';
import 'package:nas2cloud/event/bus.dart';
import 'package:nas2cloud/pages/config.dart';
import 'package:nas2cloud/pages/home.dart';
import 'package:nas2cloud/pages/login.dart';
import 'package:nas2cloud/pages/splash.dart';
import 'package:nas2cloud/pages/test.dart';
import 'package:nas2cloud/themes/app_theme.dark.dart';
import 'package:nas2cloud/themes/app_theme_light.dart';

void main() {
  AppConfig.initialize().then(
    (value) => runApp(MyApp()),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    eventBus.on<EventChangeTheme>().listen((event) {
      setState(() {});
    });
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
            theme: data.ligthTheme,
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
        appName: AppConfig.defaultAppName, theme: AppConfig.themeFollowSystem);
  }

  final String appName;
  final int theme;

  _MyAppModel({required this.appName, required this.theme});

  ThemeData get darkTheme => theme == AppConfig.themeLight
      ? AppLightTheme.themeData
      : AppDarkTheme.themeData;

  ThemeData get ligthTheme => theme == AppConfig.themeDark
      ? AppDarkTheme.themeData
      : AppLightTheme.themeData;
}
