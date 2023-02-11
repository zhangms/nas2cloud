import 'package:flutter/material.dart';
import 'package:nas2cloud/api/dto/file_walk_response/file.dart';
import 'package:nas2cloud/pub/app_nav.dart';

import '../../api/api.dart';
import '../../event/bus.dart';
import 'file_event.dart';

class FileItemTailingStar extends StatelessWidget {
  final int index;
  final File item;

  FileItemTailingStar(this.index, this.item);

  @override
  Widget build(BuildContext context) {
    return IconButton(
        onPressed: () => onPressed(context),
        icon: Icon(
          Icons.star,
          color: Colors.yellowAccent,
        ));
  }

  Future<void> onPressed(BuildContext context) async {
    Future.delayed(Duration(milliseconds: 20), () {
      showDialog(
          context: context,
          builder: ((context) {
            return AlertDialog(
              title: Text("取消收藏"),
              content: Text("确认取消收藏?"),
              actions: [
                TextButton(
                    onPressed: (() {
                      AppNav.pop(context);
                    }),
                    child: Text("取消")),
                TextButton(
                    onPressed: (() {
                      AppNav.pop(context);
                      removeFavor();
                    }),
                    child: Text("确定"))
              ],
            );
          }));
    });
  }

  Future<void> removeFavor() async {
    await Api().postToggleFavor(item.path, item.favorName ?? item.name);
    eventBus.fire(FileEvent(
      type: FileEventType.toggleFavor,
      currentPath: item.path,
      source: "$index",
      item: item,
    ));
  }
}
