import 'package:flutter/material.dart';

import '../../api/api.dart';
import '../../api/dto/file_walk_response/file.dart';
import '../../api/dto/result.dart';
import '../../event/bus.dart';
import '../../pub/app_message.dart';
import '../../pub/app_nav.dart';
import '../downloader/downloader.dart';
import 'file_event.dart';

class FileItemContextMenuBuilder {
  final String currentPath;
  final int index;
  final File item;

  FileItemContextMenuBuilder(this.currentPath, this.index, this.item);

  buildDialog(BuildContext context) {
    return SimpleDialog(
      children: _buildContextMenu(context),
    );
  }

  List<Widget> _buildContextMenu(BuildContext context) {
    List<Widget> ret = [];
    if (item.type == "DIR") {
      if (item.favor ?? false) {
        ret.add(SimpleDialogOption(
          onPressed: () => _onPressFavor(context),
          child: ListTile(
            leading: Icon(Icons.star),
            title: Text("取消收藏"),
          ),
        ));
      } else {
        ret.add(SimpleDialogOption(
          onPressed: () => _onPressFavor(context),
          child: ListTile(
            leading: Icon(Icons.star, color: Colors.orange),
            title: Text("收藏"),
          ),
        ));
      }
    } else {
      ret.add(SimpleDialogOption(
        onPressed: () => _onPressDownload(context),
        child: ListTile(
          leading: Icon(Icons.download),
          title: Text("下载"),
        ),
      ));
    }
    ret.add(SimpleDialogOption(
      onPressed: () => _onPressDelete(context),
      child: ListTile(
        leading: Icon(Icons.delete),
        title: Text("删除"),
      ),
    ));
    return ret;
  }

  _onPressDownload(BuildContext context) async {
    AppNav.pop(context);
    if (item.type == "DIR") {
      return;
    }
    var path = await Api().getStaticFileUrl(item.path);
    Downloader.platform.download(path);
    if (context.mounted) {
      AppMessage.show(context, "已开始下载, 请从状态栏查看下载进度");
    }
  }

  void _onPressDelete(BuildContext context) {
    AppNav.pop(context);
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
                      AppNav.pop(context);
                    }),
                    child: Text("取消")),
                TextButton(
                    onPressed: (() {
                      AppNav.pop(context);
                      _deleteFile(context);
                    }),
                    child: Text("确定"))
              ],
            );
          }));
    });
  }

  _deleteFile(BuildContext context) async {
    print("delete ${item.path}");
    Result result = await Api().postDeleteFile(item.path);
    if (!result.success) {
      if (context.mounted) {
        AppMessage.show(context, result.message!);
      }
      return;
    }
    eventBus.fire(FileEvent(
      type: FileEventType.delete,
      currentPath: currentPath,
      source: "$index",
      item: item,
    ));
    if (context.mounted) {
      AppMessage.show(context, "删除成功");
    }
  }

  _onPressFavor(BuildContext context) {
    AppNav.pop(context);
    if (item.favor ?? false) {
      _toggleFavor(item.path, item.favorName ?? "");
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
              _toggleFavor(item.path, name);
            }),
            child: Text("确定"))
      ],
    );
  }

  Future<void> _toggleFavor(String fullPath, String favorName) async {
    await Api().postToggleFavor(fullPath, favorName);
    eventBus.fire(FileEvent(
      type: FileEventType.toggleFavor,
      currentPath: currentPath,
      source: "$index",
      item: item,
    ));
  }
}
