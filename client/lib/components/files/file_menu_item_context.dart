import 'package:flutter/material.dart';
import 'package:nas2cloud/api/api.dart';
import 'package:nas2cloud/api/dto/file_walk_response/file.dart';
import 'package:nas2cloud/api/dto/result.dart';
import 'package:nas2cloud/components/downloader/downloader.dart';
import 'package:nas2cloud/components/files/file_event.dart';
import 'package:nas2cloud/event/bus.dart';
import 'package:nas2cloud/themes/app_nav.dart';
import 'package:nas2cloud/themes/widgets.dart';

class FileItemContextMenu extends StatefulWidget {
  final int index;
  final File item;
  final String currentPath;

  FileItemContextMenu(this.index, this.item, this.currentPath);

  @override
  State<FileItemContextMenu> createState() => _FileItemContextMenuState();
}

class _FileItemContextMenuState extends State<FileItemContextMenu> {
  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<Text>(
      icon: Icon(
        Icons.more_horiz_rounded,
      ),
      itemBuilder: (context) {
        return [
          if (widget.item.type != "DIR")
            PopupMenuItem(
              child: ListTile(
                leading: Icon(Icons.download),
                title: Text("下载"),
              ),
              onTap: () => download(widget.item),
            ),
          PopupMenuItem(
            child: ListTile(
              leading: Icon(Icons.delete),
              title: Text("删除"),
            ),
            onTap: () => showItemDeleteConfirm(widget.item),
          ),
        ];
      },
    );
  }

  void download(File item) async {
    if (item.type == "DIR") {
      return;
    }
    var path = await Api().getStaticFileUrl(item.path);
    Downloader.platform.download(path);
    setState(() {
      AppWidgets.showMessage(context, "已开始下载, 请从状态栏查看下载进度");
    });
  }

  void showItemDeleteConfirm(File item) {
    Future.delayed(Duration(milliseconds: 20), () {
      showDialog(
          context: context,
          builder: ((context) {
            return AlertDialog(
              title: Text("删除文件"),
              content: Text("确认删除 ${item.name} ?"),
              actions: [
                TextButton(
                    onPressed: (() {
                      pop();
                    }),
                    child: Text("取消")),
                TextButton(
                    onPressed: (() {
                      deleteFile(item);
                      pop();
                    }),
                    child: Text("确定"))
              ],
            );
          }));
    });
  }

  Future<void> deleteFile(File item) async {
    print("delete ${item.path}");
    Result result = await Api().postDeleteFile(item.path);
    if (!result.success) {
      setState(() {
        AppWidgets.showMessage(context, result.message!);
      });
      return;
    }
    eventBus.fire(FileEvent(
      type: FileEventType.delete,
      currentPath: widget.currentPath,
      source: "${widget.index}",
      item: item,
    ));
    setState(() {
      AppWidgets.showMessage(context, "删除成功");
    });
  }

  void pop() {
    AppWidgets.clearMessage(context);
    AppNav.pop(context);
  }
}
