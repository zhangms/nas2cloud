import 'package:flutter/material.dart';
import 'package:nas2cloud/api/app_storage.dart';
import 'package:nas2cloud/app.dart';
import 'package:nas2cloud/pages/scaffold.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    var appName = appStorage.getHostState()?.appName ?? "Nas2cloud";
    return ChangeNotifierProvider(
      create: (context) => AppState(),
      child: MaterialApp(
        title: appName,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        ),
        home: ScaffoldPage(),
      ),
    );
  }
}
