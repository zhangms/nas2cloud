import 'package:flutter/material.dart';
import 'package:nas2cloud/components/files/file_favorite.dart';

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
    return PopupMenuButton<Text>(
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

  PopupMenuItem<Text> buildDownloadMenu(File item) {
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

  onTapFavorite(File item) async {
    var isFavorite = await FileFavorite.isFavorite(item.path);
    if (isFavorite) {
      FileFavorite.remove(item.path);
      return;
    }
    Future.delayed(const Duration(milliseconds: 100), (() {
      showDialog(
        context: context,
        builder: ((context) => FileFavorite.buildFavoriteDialog(context, item)),
      );
    }));
  }

  PopupMenuItem<Text> buildFavoriteMenu(File item) {
    return PopupMenuItem(
      child: FutureBuilder<bool>(
          future: FileFavorite.isFavorite(item.path),
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data!) {
              return ListTile(
                leading: Icon(Icons.favorite),
                title: Text("取消收藏"),
              );
            }
            return ListTile(
              leading: Icon(
                Icons.favorite,
                color: Colors.red,
              ),
              title: Text("收藏"),
            );
          }),
      onTap: () => onTapFavorite(widget.item),
    );
  }
}
