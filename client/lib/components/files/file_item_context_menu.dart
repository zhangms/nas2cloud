import 'package:flutter/material.dart';

import '../../api/api.dart';
import '../../dto/file_walk_response.dart';
import '../../dto/result.dart';
import '../../event/bus.dart';
import '../../pub/app_message.dart';
import '../../pub/app_nav.dart';
import '../downloader/downloader.dart';
import '../uploader/auto_uploader.dart';
import 'file_event.dart';

class FileItemContextMenuBuilder {
  final String currentPath;
  final int index;
  final FileWalkResponseDataFiles item;
  final bool? isAutoUploaded;

  FileItemContextMenuBuilder({
    required this.currentPath,
    required this.index,
    required this.item,
    this.isAutoUploaded,
  });

  buildDialog(BuildContext context) {
    return SimpleDialog(
      children: _buildContextMenu(context),
    );
  }

  List<Widget> _buildContextMenu(BuildContext context) {
    List<Widget> ret = [];
    ret.add(SimpleDialogOption(
      onPressed: () => _onPressInfo(context),
      child: ListTile(
        leading: Icon(Icons.info),
        title: Text("详情"),
      ),
    ));
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
    if ((isAutoUploaded ?? false) && item.type == "FILE") {
      ret.add(SimpleDialogOption(
        onPressed: () => _onPressReUpload(context),
        child: ListTile(
          leading: Icon(Icons.upload),
          title: Text("重新自动上传"),
        ),
      ));
    }
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
                      _deleteFile(context, true);
                    }),
                    child: Text("确定"))
              ],
            );
          }));
    });
  }

  Future<bool> _deleteFile(BuildContext context, bool notify) async {
    print("delete ${item.path}");
    Result result = await Api().postDeleteFile(item.path);
    if (!result.success) {
      if (context.mounted) {
        AppMessage.show(context, result.message!);
      }
      return false;
    }
    eventBus.fire(FileEvent(
      type: FileEventType.delete,
      currentPath: currentPath,
      source: "$index",
      item: item,
    ));
    if (notify && context.mounted) {
      AppMessage.show(context, "删除成功");
    }
    return true;
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

  buildFavoriteDialog(BuildContext context, FileWalkResponseDataFiles item) {
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

  _onPressReUpload(BuildContext context) async {
    AppNav.pop(context);
    if (!(isAutoUploaded ?? false)) {
      return;
    }
    await _deleteFile(context, false);
    int clearTaskCount = await AutoUploader().clearTaskByFile(item.path);
    print("clearAutoUploadTaskCount-->$clearTaskCount");
  }

  _onPressInfo(BuildContext context) {
    String detail = "名称：${item.name}\n";
    detail += "路径：${item.path}\n";
    detail += "大小：${item.size}\n";
    detail += "修改时间：${item.modTime}\n";
    Future.delayed(Duration(milliseconds: 10), () {
      showDialog(
          context: context,
          builder: ((context) {
            return AlertDialog(
              title: Text("详情"),
              content: SelectableText(detail),
            );
          }));
    });
  }
}
