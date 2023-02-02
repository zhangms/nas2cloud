import 'package:flutter/material.dart';
import 'package:nas2cloud/api/app_config.dart';
import 'package:nas2cloud/app.dart';
import 'package:nas2cloud/themes/widgets.dart';
import 'package:provider/provider.dart';

class SettingPage extends StatefulWidget {
  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  late AppState appState;

  @override
  Widget build(BuildContext context) {
    appState = context.watch<AppState>();
    return Scaffold(
      appBar: buildAppBar(),
      body: buildBody(),
    );
  }

  buildAppBar() {
    return AppBar(
      leading: IconButton(
        icon: Icon(Icons.arrow_back),
        onPressed: () {
          Navigator.of(context).pop();
        },
      ),
      title: AppWidgets.getAppNameText(),
    );
  }

  buildBody() {
    return SafeArea(
      child: ListView(
        children: [
          buildAutoUploadSetting(),
          ...buildColorSetting(),
        ],
      ),
    );
  }

  List<Widget> buildColorSetting() {
    return [
      ListTile(
        title: Text("外观"),
      ),
      FutureBuilder<int>(
          future: AppConfig.getTheme(),
          builder: (context, snapshot) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ChoiceChip(
                  label: Text("跟随系统"),
                  selected: snapshot.hasData && snapshot.data == 0,
                  onSelected: (value) {
                    appState.changeTheme(0);
                  },
                ),
                ChoiceChip(
                  label: Text("浅色模式"),
                  selected: snapshot.hasData && snapshot.data == 1,
                  onSelected: (value) {
                    appState.changeTheme(1);
                  },
                ),
                ChoiceChip(
                  label: Text("深色模式"),
                  selected: snapshot.hasData && snapshot.data == 2,
                  onSelected: (value) {
                    appState.changeTheme(2);
                  },
                ),
              ],
            );
          }),
    ];
  }

  buildAutoUploadSetting() {
    return ListTile(
      title: Text("仅WLAN下自动上传"),
      trailing: Switch(
          value: true,
          onChanged: (value) {
            print("value");
          }),
    );
  }
}
