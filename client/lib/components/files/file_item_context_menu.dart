import 'package:flutter/material.dart';

import '../../api/api.dart';
import '../../api/dto/file_walk_response/file.dart';
import '../../api/dto/result.dart';
import '../../event/bus.dart';
import '../../pub/app_message.dart';
import '../../pub/app_nav.dart';
import '../downloader/downloader.dart';
import 'file_event.dart';

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
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_horiz_rounded,
      ),
      itemBuilder: (context) {
        return [
          if (widget.item.type != "DIR") buildDownloadMenu(widget.item),
          if (widget.item.type == "DIR") buildFavoriteMenu(widget.item),
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

  PopupMenuItem<String> buildDownloadMenu(File item) {
    return PopupMenuItem(
      child: ListTile(
        leading: Icon(Icons.download),
        title: Text("下载"),
      ),
      onTap: () => download(widget.item),
    );
  }

  void download(File item) async {
    if (item.type == "DIR") {
      return;
    }
    var path = await Api().getStaticFileUrl(item.path);
    Downloader.platform.download(path);
    if (mounted) {
      AppMessage.show(context, "已开始下载, 请从状态栏查看下载进度");
    }
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
      if (mounted) {
        AppMessage.show(context, result.message!);
      }
      return;
    }
    eventBus.fire(FileEvent(
      type: FileEventType.delete,
      currentPath: widget.currentPath,
      source: "${widget.index}",
      item: item,
    ));
    if (mounted) {
      AppMessage.show(context, "删除成功");
    }
  }

  void pop() {
    AppMessage.clear(context);
    AppNav.pop(context);
  }

  PopupMenuItem<String> buildFavoriteMenu(File item) {
    if (item.favor ?? false) {
      return PopupMenuItem(
        child: ListTile(
          leading: Icon(Icons.star),
          title: Text("取消收藏"),
        ),
        onTap: () => onTapFavorite(item),
      );
    }
    return PopupMenuItem(
      child: ListTile(
        leading: Icon(
          Icons.star,
          color: Colors.yellowAccent,
        ),
        title: Text("收藏"),
      ),
      onTap: () => onTapFavorite(item),
    );
  }

  onTapFavorite(File item) {
    if (item.favor ?? false) {
      toggleFavor(item.path, item.favorName ?? "");
      return;
    }
    Future.delayed(const Duration(milliseconds: 100), (() {
      showDialog(
        context: context,
        builder: ((context) => buildFavoriteDialog(context, item)),
      );
    }));
  }

  buildFavoriteDialog(BuildContext context, File item) {
    var input = TextEditingController();
    input.text = item.name;
    return AlertDialog(
      title: Text("收藏"),
      content: TextField(
        controller: input,
        decoration: InputDecoration(
          labelText: "收藏名称",
        ),
      ),
      actions: [
        TextButton(
            onPressed: (() {
              input.dispose();
              AppNav.pop(context);
            }),
            child: Text("取消")),
        TextButton(
            onPressed: (() {
              var name = input.text;
              input.dispose();
              AppNav.pop(context);
              toggleFavor(item.path, name);
            }),
            child: Text("确定"))
      ],
    );
  }

  Future<void> toggleFavor(String fullPath, String favorName) async {
    await Api().postToggleFavor(fullPath, favorName);
    eventBus.fire(FileEvent(
      type: FileEventType.toggleFavor,
      currentPath: widget.currentPath,
      source: "${widget.index}",
      item: widget.item,
    ));
  }
}
