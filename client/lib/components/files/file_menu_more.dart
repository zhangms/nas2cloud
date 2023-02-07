import 'package:flutter/material.dart';
import 'package:nas2cloud/themes/app_nav.dart';

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

  FileMoreMenu(this.currentPath);

  @override
  State<FileMoreMenu> createState() => _FileMoreMenuState();
}

class _FileMoreMenuState extends State<FileMoreMenu> {
  late String orderBy;

  @override
  void initState() {
    super.initState();
    orderBy = "fileName";
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<Text>(
      icon: Icon(
        Icons.more_horiz,
      ),
      itemBuilder: (context) {
        return [
          for (var i = 0; i < FileMoreMenu._orderByOptions.length; i++)
            PopupMenuItem(
              enabled: FileMoreMenu._orderByOptions[i]["orderBy"]! != orderBy,
              child: Text(FileMoreMenu._orderByOptions[i]["name"]!),
              onTap: () =>
                  changeOrderBy(FileMoreMenu._orderByOptions[i]["orderBy"]!),
            ),
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
    // if (orderBy != order) {
    //   resetFetch(order);
    // }
  }

  void showCurrentPath() {
    // Future.delayed(Duration(milliseconds: 10), () {
    //   showDialog(
    //       context: context,
    //       builder: ((context) {
    //         return AlertDialog(
    //           title: Text("当前位置"),
    //           content: SelectableText(widget.path),
    //         );
    //       }));
    // });
  }
}
