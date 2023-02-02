import 'package:flutter/material.dart';
import 'package:nas2cloud/themes/widgets.dart';

class SettingPage extends StatefulWidget {
  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  @override
  Widget build(BuildContext context) {
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
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ChoiceChip(
            label: Text("浅色模式"),
            selected: false,
            onSelected: (value) {
              print(value);
            },
          ),
          ChoiceChip(
            label: Text("深色模式"),
            selected: false,
            onSelected: (value) {
              print(value);
            },
          ),
          ChoiceChip(
            label: Text("跟随系统"),
            selected: true,
            onSelected: (value) {
              print(value);
            },
          )
        ],
      ),
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
