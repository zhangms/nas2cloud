import 'package:flutter/material.dart';

import '../../pub/app_nav.dart';

class FileMoreMenu extends StatelessWidget {
  final String currentPath;

  FileMoreMenu(this.currentPath);

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_horiz,
      ),
      itemBuilder: (context) {
        return [
          PopupMenuItem(
            onTap: (() => showCurrentPath(context)),
            child: Text("显示当前位置"),
          ),
          PopupMenuItem(
            onTap: () => AppNav.gohome(context),
            child: Text("回到首页"),
          ),
        ];
      },
    );
  }

  void showCurrentPath(BuildContext context) {
    Future.delayed(Duration(milliseconds: 10), () {
      showDialog(
          context: context,
          builder: ((context) {
            return AlertDialog(
              title: Text("当前位置"),
              content: SelectableText(currentPath),
            );
          }));
    });
  }
}
