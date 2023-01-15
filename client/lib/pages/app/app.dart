import 'package:flutter/material.dart';
import 'package:nas2cloud/api/state_response/data.dart';
import 'package:nas2cloud/app.dart';

class AppPage extends StatefulWidget {
  @override
  State<AppPage> createState() => _AppPageState();
}

class _AppPageState extends State<AppPage> {
  @override
  Widget build(BuildContext context) {
    var hostState = appStorage.getHostState();

    return Scaffold(
      appBar: buildAppBar(hostState),
      body: SafeArea(child: Text("hello world")),
    );
  }

  AppBar buildAppBar(Data? hostState) {
    var theme = Theme.of(context);
    return AppBar(
      backgroundColor: theme.primaryColor,
      leading: IconButton(
        icon: Icon(
          Icons.menu,
          color: theme.primaryIconTheme.color,
        ),
        onPressed: () {},
      ),
      title: Text(
        hostState?.appName ?? "Nas2cloud",
        style: theme.primaryTextTheme.titleMedium,
      ),
    );
  }
}
