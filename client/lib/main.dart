import 'package:flutter/material.dart';
import 'package:nas2cloud/api/app_config.dart';
import 'package:nas2cloud/app.dart';
import 'package:nas2cloud/pages/home.dart';
import 'package:nas2cloud/pages/test.dart';
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
    return FutureBuilder<_MyAppConfig>(
        future: getMyAppConfig(),
        builder: (context, snapshot) {
          return MaterialApp(
            title: getTitle(snapshot.data),
            // home: HomePage(),
            theme: getLightTheme(snapshot.data),
            darkTheme: getDarkTheme(snapshot.data),
            home: TestPage(),
            routes: <String, WidgetBuilder>{
              "/home": (_) => HomePage(),
            },
          );
        });
  }

  Future<_MyAppConfig> getMyAppConfig() async {
    return _MyAppConfig(
      appName: await AppConfig.getAppName(),
      theme: await AppConfig.getTheme(),
    );
  }

  getLightTheme(_MyAppConfig? data) {
    var theme = data?.theme ?? 0;
    return theme == 2 ? AppDarkTheme.themeData : AppLightTheme.themeData;
  }

  getDarkTheme(_MyAppConfig? data) {
    var theme = data?.theme ?? 0;
    return theme == 1 ? AppLightTheme.themeData : AppDarkTheme.themeData;
  }

  getTitle(_MyAppConfig? data) {
    return data == null ? "Nas2cloud" : data.appName;
  }
}

class _MyAppConfig {
  final String appName;
  final int theme;

  _MyAppConfig({required this.appName, required this.theme});
}
