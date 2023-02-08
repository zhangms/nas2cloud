import 'package:flutter/material.dart';

import '../../event/bus.dart';
import '../../themes/app_nav.dart';
import 'file_event.dart';

class FileMoreMenu extends StatefulWidget {
  static const _orderByOptions = [
    {"orderBy": "modTime_desc", "name": "最新修改在前"},
    {"orderBy": "modTime_asc", "name": "最早修改在前"},
    {"orderBy": "creTime_desc", "name": "最新添加"},
    {"orderBy": "size_asc", "name": "文件从小到大"},
    {"orderBy": "size_desc", "name": "文件从大到小"},
    {"orderBy": "fileName", "name": "文件名排序"},
  ];

  final String currentPath;
  final String orderByInitValue;

  FileMoreMenu(this.currentPath, this.orderByInitValue);

  @override
  State<FileMoreMenu> createState() => _FileMoreMenuState();
}

class _FileMoreMenuState extends State<FileMoreMenu> {
  late String orderby;

  @override
  void initState() {
    super.initState();
    orderby = widget.orderByInitValue;
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<Text>(
      icon: Icon(
        Icons.more_horiz,
      ),
      itemBuilder: (context) {
        return [
          ...buildOrderByMenu(),
          PopupMenuDivider(),
          PopupMenuItem(
            onTap: (() => showCurrentPath()),
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

  changeOrderBy(String order) {
    if (orderby != order) {
      setState(() {
        orderby = order;
        eventBus.fire(FileEvent(
          type: FileEventType.orderBy,
          currentPath: widget.currentPath,
          source: order,
        ));
      });
    }
  }

  void showCurrentPath() {
    Future.delayed(Duration(milliseconds: 10), () {
      showDialog(
          context: context,
          builder: ((context) {
            return AlertDialog(
              title: Text("当前位置"),
              content: SelectableText(widget.currentPath),
            );
          }));
    });
  }

  List<PopupMenuItem<Text>> buildOrderByMenu() {
    List<PopupMenuItem<Text>> ret = [];
    for (var i = 0; i < FileMoreMenu._orderByOptions.length; i++) {
      var menu = PopupMenuItem<Text>(
        enabled: FileMoreMenu._orderByOptions[i]["orderBy"]! != orderby,
        child: Text(FileMoreMenu._orderByOptions[i]["name"]!),
        onTap: () => changeOrderBy(FileMoreMenu._orderByOptions[i]["orderBy"]!),
      );
      ret.add(menu);
    }
    return ret;
  }
}
