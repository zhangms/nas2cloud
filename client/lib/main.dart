import 'package:flutter/material.dart';
import 'package:nas2cloud/app.dart';
import 'package:nas2cloud/pages/scaffold.dart';
import 'package:nas2cloud/themes/app_theme_light.dart';
import 'package:provider/provider.dart';

import 'bootstrap.dart';

void main() async {
  await initBeforeRunApp();
  runApp(MyApp());
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
        // darkTheme: AppDarkTheme.themeData,
        home: ScaffoldPage(),
        routes: <String, WidgetBuilder>{
          "/home": (_) => ScaffoldPage(),
        },
      ),
    );
  }
}
