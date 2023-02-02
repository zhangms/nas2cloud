import 'package:flutter/material.dart';
import 'package:nas2cloud/api/app_config.dart';
import 'package:nas2cloud/app.dart';
import 'package:nas2cloud/pages/home.dart';
import 'package:nas2cloud/themes/app_theme.dark.dart';
import 'package:nas2cloud/themes/app_theme_light.dart';
import 'package:provider/provider.dart';

void main() {
  AppConfig.initialize().then(
    (value) => runApp(MyApp()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppState(),
      child: _MyApp(),
    );
  }
}

class _MyApp extends StatefulWidget {
  @override
  State<_MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<_MyApp> {
  @override
  Widget build(BuildContext context) {
    context.watch<AppState>();
    return FutureBuilder<_MyAppModel>(
        future: getMyAppConfig(),
        builder: (context, snapshot) {
          _MyAppModel data = snapshot.data ?? _MyAppModel.getDefaultValue();
          return MaterialApp(
            title: data.appName,
            home: HomePage(),
            // home: TestPage(),
            theme: getLightTheme(data),
            darkTheme: getDarkTheme(data),
            routes: <String, WidgetBuilder>{
              "/home": (_) => HomePage(),
            },
          );
        });
  }

  Future<_MyAppModel> getMyAppConfig() async {
    return _MyAppModel(
      appName: await AppConfig.getAppName(),
      theme: await AppConfig.getThemeSetting(),
    );
  }

  getLightTheme(_MyAppModel data) {
    return data.theme == AppConfig.themeDark
        ? AppDarkTheme.themeData
        : AppLightTheme.themeData;
  }

  getDarkTheme(_MyAppModel data) {
    return data.theme == AppConfig.themeLight
        ? AppLightTheme.themeData
        : AppDarkTheme.themeData;
  }
}

class _MyAppModel {
  final String appName;
  final int theme;

  _MyAppModel({required this.appName, required this.theme});

  static getDefaultValue() {
    return _MyAppModel(
        appName: AppConfig.defaultAppName, theme: AppConfig.themeFollowSystem);
  }
}
