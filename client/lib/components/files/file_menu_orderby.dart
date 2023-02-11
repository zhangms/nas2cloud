import 'package:flutter/material.dart';

import '../../event/bus.dart';
import 'file_event.dart';

class FileOrderByMenu extends StatefulWidget {
  static const _orderByOptions = [
    {"orderBy": "modTime", "name": "修改时间"},
    {"orderBy": "creTime", "name": "添加时间"},
    {"orderBy": "size", "name": "文件大小"},
    {"orderBy": "fileName", "name": "文件名称"},
  ];

  final String currentPath;
  final String orderByInitValue;

  FileOrderByMenu(this.currentPath, this.orderByInitValue);

  @override
  State<FileOrderByMenu> createState() => _FileOrderByMenuState();
}

class _FileOrderByMenuState extends State<FileOrderByMenu> {
  late String orderByField;
  late String orderByDirection;

  @override
  void initState() {
    super.initState();
    var order = widget.orderByInitValue.split("_");
    orderByField = order[0];
    orderByDirection = order[1];
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<Text>(
      icon: Icon(
        Icons.sort,
      ),
      itemBuilder: (context) {
        return buildOrderByMenu();
      },
    );
  }

  List<PopupMenuItem<Text>> buildOrderByMenu() {
    List<PopupMenuItem<Text>> ret = [];
    for (var i = 0; i < FileOrderByMenu._orderByOptions.length; i++) {
      var option = FileOrderByMenu._orderByOptions[i];
      var menu = PopupMenuItem<Text>(
        child: buildOrderByMenuView(option),
        onTap: () => changeOrderBy(option["orderBy"]!),
      );
      ret.add(menu);
    }
    return ret;
  }

  buildOrderByMenuView(Map<String, String> option) {
    if (orderByField != option["orderBy"]) {
      return ListTile(
        title: Text(option["name"]!),
      );
    }
    if (orderByDirection == "desc") {
      return ListTile(
        title: Text(option["name"]!),
        trailing: Icon(Icons.arrow_drop_down),
      );
    }
    return ListTile(
      title: Text(option["name"]!),
      trailing: Icon(Icons.arrow_drop_up),
    );
  }

  changeOrderBy(String order) {
    var field = orderByField;
    var direction = orderByField;
    if (orderByField == order) {
      if (orderByDirection == "desc") {
        direction = "asc";
      } else {
        direction = "desc";
      }
    } else {
      field = order;
      direction = "asc";
    }
    setState(() {
      orderByField = field;
      orderByDirection = direction;
      eventBus.fire(FileEvent(
        type: FileEventType.orderBy,
        currentPath: widget.currentPath,
        source: "${field}_$direction",
      ));
    });
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
}
