import 'package:flutter/material.dart';
import 'package:nas2cloud/api/api.dart';
import 'package:nas2cloud/api/app_config.dart';
import 'package:nas2cloud/api/dto/result.dart';
import 'package:nas2cloud/components/downloader/downloader.dart';
import 'package:nas2cloud/themes/widgets.dart';

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
              onTap: () => _download(updates),
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
        .download(await Api().getStaticFileUrl(updates.downlink));
    setState(() {
      AppWidgets.showMessage(context, "已开始下载，从状态栏查看下载进度");
    });
  }
}

class _AppUpdate {
  String downlink;
  String version;
  bool hasUpdate;

  _AppUpdate(this.downlink, this.version, this.hasUpdate);
}
