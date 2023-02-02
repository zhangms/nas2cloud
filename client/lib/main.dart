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
      child: MaterialApp(
        title: "Nas2cloud",
        theme: AppLightTheme.themeData,
        darkTheme: AppDarkTheme.themeData,
        // home: HomePage(),
        home: TestPage(),
        routes: <String, WidgetBuilder>{
          "/home": (_) => HomePage(),
        },
      ),
    );
  }
}
