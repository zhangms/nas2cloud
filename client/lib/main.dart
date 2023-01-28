import 'package:flutter/material.dart';
import 'package:nas2cloud/app.dart';
import 'package:nas2cloud/pages/home.dart';
import 'package:nas2cloud/themes/app_theme_light.dart';
import 'package:nas2cloud/utils/spu.dart';
import 'package:provider/provider.dart';

import 'components/downloader.dart';
import 'components/notification/notification.dart';
import 'components/uploader/file_uploder.dart';

void main() async {
  await initBeforeRunApp();
  runApp(MyApp());
}

initBeforeRunApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  await spu.initSharedPreferences();
  await LocalNotification.get().init();
  await Downloader.get().init();
  await FileUploader.get().init();
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
        home: HomePage(),
        routes: <String, WidgetBuilder>{
          "/home": (_) => HomePage(),
        },
      ),
    );
  }
}
