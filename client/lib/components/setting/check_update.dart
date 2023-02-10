import 'package:flutter/material.dart';

import '../../api/api.dart';
import '../../api/app_config.dart';
import '../../api/dto/result.dart';
import '../../pub/app_message.dart';
import '../downloader/downloader.dart';

class CheckUpdateWidget extends StatefulWidget {
  @override
  State<CheckUpdateWidget> createState() => _CheckUpdateWidgetState();
}

class _CheckUpdateWidgetState extends State<CheckUpdateWidget> {
  static const String noUpdates = "no_updates";

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Result>(
        future: Api().getCheckUpdates(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return ListTile(
              title: Text("更新检查中..."),
            );
          }
          var updates = _parseToUpdate(snapshot.data!);
          if (!updates.hasUpdate) {
            return ListTile(
              title: Text("已是最新版本:${AppConfig.currentAppVersion}"),
            );
          }
          return ListTile(
            title: Text("下载最新版本:${updates.version}"),
            trailing: Icon(Icons.navigate_next),
            onTap: () => _download(updates),
          );
        });
  }

  _AppUpdate _parseToUpdate(Result result) {
    if (!result.success) {
      return _AppUpdate("", "", false);
    }
    var msg = result.message ?? noUpdates;
    if (msg == noUpdates) {
      return _AppUpdate("", "", false);
    }
    var list = msg.split(";");
    if (list.length < 2 || list[1] == AppConfig.currentAppVersion) {
      return _AppUpdate("", "", false);
    }
    return _AppUpdate(list[0], list[1], true);
  }

  _download(_AppUpdate updates) async {
    Downloader.platform
        .download(await Api().getStaticFileUrl(updates.downLink));
    if (mounted) {
      AppMessage.show(context, "已开始下载，从状态栏查看下载进度");
    }
  }
}

class _AppUpdate {
  String downLink;
  String version;
  bool hasUpdate;

  _AppUpdate(this.downLink, this.version, this.hasUpdate);
}
