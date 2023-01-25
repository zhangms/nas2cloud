import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:nas2cloud/app.dart';
import 'package:nas2cloud/pages/scaffold.dart';
import 'package:nas2cloud/themes/app_theme_light.dart';
import 'package:provider/provider.dart';

void main() async {
  if (!kIsWeb) {
    WidgetsFlutterBinding.ensureInitialized();
    // Plugin must be initialized before using
    await FlutterDownloader.initialize(debug: true, ignoreSsl: true);
  }
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
        home: ScaffoldPage(),
      ),
    );
  }
}
