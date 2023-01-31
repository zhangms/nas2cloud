import 'package:flutter/material.dart';
import 'package:nas2cloud/api/api.dart';
import 'package:nas2cloud/app.dart';
import 'package:nas2cloud/components/background/background.dart';
import 'package:nas2cloud/components/uploader/auto_uploader.dart';
import 'package:nas2cloud/pages/home.dart';
import 'package:nas2cloud/pages/test.dart';
import 'package:nas2cloud/themes/app_theme_light.dart';
import 'package:nas2cloud/utils/spu.dart';
import 'package:provider/provider.dart';

import 'components/downloader/downloader.dart';
import 'components/notification/notification.dart';
import 'components/uploader/file_uploder.dart';

void main() async {
  print("isInDebugMode: $isInDebugMode");
  await initBeforeRunApp();
  runApp(MyApp());
}

initBeforeRunApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Spu().initSharedPreferences();
  BackgroundProcessor().initialize();
  await LocalNotification.platform.initialize();
  await Downloader.platform.initialize();
  await FileUploader.platform.initialize();
  AutoUploader().initialize();
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
        // home: HomePage(),
        home: TestPage(),
        routes: <String, WidgetBuilder>{
          "/home": (_) => HomePage(),
        },
      ),
    );
  }
}
