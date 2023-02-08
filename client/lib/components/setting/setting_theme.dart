import 'package:flutter/material.dart';

import '../../api/app_config.dart';
import '../../event/bus.dart';
import '../../event/event_change_theme.dart';

class SettingThemeWidget extends StatefulWidget {
  @override
  State<SettingThemeWidget> createState() => _SettingThemeWidgetState();
}

class _SettingThemeWidgetState extends State<SettingThemeWidget> {
  int myTheme = -1;

  @override
  void initState() {
    super.initState();
    AppConfig.getThemeSetting().then((value) {
      setState(() {
        myTheme = value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: Text("外观模式"),
        ),
        ListTile(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ChoiceChip(
                label: Text("跟随系统"),
                selected: myTheme == AppConfig.themeFollowSystem,
                onSelected: (value) => changeTheme(AppConfig.themeFollowSystem),
              ),
              ChoiceChip(
                label: Text("浅色模式"),
                selected: myTheme == AppConfig.themeLight,
                onSelected: (value) => changeTheme(AppConfig.themeLight),
              ),
              ChoiceChip(
                label: Text("深色模式"),
                selected: myTheme == AppConfig.themeDark,
                onSelected: (value) => changeTheme(AppConfig.themeDark),
              ),
            ],
          ),
        ),
      ],
    );
  }

  changeTheme(int theme) async {
    await AppConfig.setThemeSetting(theme);
    setState(() {
      myTheme = theme;
      eventBus.fire(EventChangeTheme(theme));
    });
  }
}
