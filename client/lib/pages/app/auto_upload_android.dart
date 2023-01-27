import 'dart:io';

import 'package:flutter/material.dart';
import 'package:nas2cloud/themes/widgets.dart';
import 'package:path/path.dart' as p;

class AndroidAutoUploadConfigWidget extends StatefulWidget {
  @override
  State<AndroidAutoUploadConfigWidget> createState() =>
      _AndroidAutoUploadConfigWidgetState();
}

class _AndroidAutoUploadConfigWidgetState
    extends State<AndroidAutoUploadConfigWidget> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<_AndroidAutoUploadDirConfig>>(
        future: getAutoUploadConfig(),
        builder: (context, snapshot) {
          return buildBody(snapshot);
        });
  }

  static const String rootdir = "/storage/emulated/0/";

  Future<List<_AndroidAutoUploadDirConfig>> getAutoUploadConfig() async {
    List<_AndroidAutoUploadDirConfig> result = [];
    Directory directory = Directory(rootdir);
    var files = directory.listSync();
    for (var f in files) {
      if (await isSupportedAutoUploadDir(f)) {
        result.add(getUploadConfig(f.path));
      }
    }
    result.sort(sortUploadConfig);
    return Future.value(result);
  }

  Widget buildBody(AsyncSnapshot<List<_AndroidAutoUploadDirConfig>> snapshot) {
    if (!snapshot.hasData) {
      return AppWidgets.getPageLoadingView();
    }
    List<_AndroidAutoUploadDirConfig> configs = snapshot.data ?? [];
    return ListView(
      children: [
        ListTile(
          title: Text("配置本机上传到云端的目录"),
        ),
        Divider(),
        for (var cfg in configs)
          ListTile(
            leading: cfg.autoupload
                ? Icon(
                    Icons.cloud,
                    color: Colors.green,
                  )
                : Icon(Icons.cloud_off),
            trailing: Icon(Icons.navigate_next),
            title: Text(cfg.name),
            subtitle: cfg.remote != null ? Text(cfg.remote!) : null,
            onTap: () => viewAutoUploadConfig(cfg),
          ),
      ],
    );
  }

  viewAutoUploadConfig(_AndroidAutoUploadDirConfig cfg) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _AndroidAutoUploadConfigView(cfg),
      ),
    );
  }

  Future<bool> isSupportedAutoUploadDir(FileSystemEntity f) async {
    if (!await FileSystemEntity.isDirectory(f.path)) {
      return false;
    }
    var name = p.basename(f.path);
    if (name.startsWith(".")) {
      return false;
    }
    if (name.toLowerCase() == "android") {
      return false;
    }
    if (name.toLowerCase() == "miui") {
      return false;
    }
    return true;
  }

  int sortUploadConfig(
      _AndroidAutoUploadDirConfig a, _AndroidAutoUploadDirConfig b) {
    if (a.autoupload && !b.autoupload) {
      return -1;
    }
    if (!a.autoupload && b.autoupload) {
      return 1;
    }
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  }

  _AndroidAutoUploadDirConfig getUploadConfig(String path) {
    return _AndroidAutoUploadDirConfig(
        name: p.basename(path), path: path, autoupload: false);
  }
}

class _AndroidAutoUploadDirConfig {
  String name;
  String path;
  String? remote;
  bool autoupload;

  _AndroidAutoUploadDirConfig({
    required this.name,
    required this.path,
    required this.autoupload,
    this.remote,
  });
}

class _AndroidAutoUploadConfigView extends StatelessWidget {
  final _AndroidAutoUploadDirConfig config;

  _AndroidAutoUploadConfigView(this.config);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(context),
      body: buildBody(),
    );
  }

  buildAppBar(BuildContext context) {
    return AppBar(
      leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(Icons.close)),
      actions: [
        TextButton(
          child: Text("保存"),
          onPressed: () => print("X"),
        )
      ],
    );
  }

  Widget buildBody() {
    return ListView(
      children: [
        SwitchListTile(
            value: true, title: Text("F"), onChanged: (obj) => print("FF")),
      ],
    );
  }
}
