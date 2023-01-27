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
            leading: cfg.autoupload ? Icon(Icons.cloud) : Icon(Icons.cloud_off),
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
  final String name;
  final String path;
  String? remote;
  bool autoupload;

  _AndroidAutoUploadDirConfig({
    required this.name,
    required this.path,
    required this.autoupload,
    this.remote,
  });

  _AndroidAutoUploadDirConfig copyWith({
    String? name,
    String? path,
    String? remote,
    bool? autoupload,
  }) {
    return _AndroidAutoUploadDirConfig(
      name: name ?? this.name,
      path: path ?? this.path,
      remote: remote ?? this.remote,
      autoupload: autoupload ?? this.autoupload,
    );
  }
}

class _AndroidAutoUploadConfigView extends StatefulWidget {
  final _AndroidAutoUploadDirConfig config;

  _AndroidAutoUploadConfigView(this.config);

  @override
  State<_AndroidAutoUploadConfigView> createState() =>
      _AndroidAutoUploadConfigViewState();
}

class _AndroidAutoUploadConfigViewState
    extends State<_AndroidAutoUploadConfigView> {
  late _AndroidAutoUploadDirConfig stateConfig;

  late TextEditingController remoteLocation;

  @override
  void initState() {
    super.initState();
    stateConfig = widget.config.copyWith();
    remoteLocation = TextEditingController(text: stateConfig.remote);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(context),
      body: buildBody(),
    );
  }

  buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(stateConfig.name),
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
            value: stateConfig.autoupload,
            title: Text("自动上传"),
            onChanged: ((obj) {
              stateConfig.autoupload = !stateConfig.autoupload;
              setState(() {});
            })),
        ListTile(
          title: Text(
            "上传位置",
          ),
          subtitle: TextField(
            decoration: stateConfig.autoupload
                ? InputDecoration(hintText: "首页->more->显示当前位置")
                : InputDecoration(),
            enabled: stateConfig.autoupload,
            controller: remoteLocation,
          ),
        ),
        SizedBox(height: 10),
        buildFileGridView(),
      ],
    );
  }

  FutureBuilder<List<String>> buildFileGridView() {
    return FutureBuilder<List<String>>(
        future: getLocalFiles(),
        builder: (context, snapshot) {
          if (snapshot.data == null) {
            return Text("");
          }
          return buildFileGridImpl(snapshot.data!);
        });
  }

  Future<List<String>> getLocalFiles() async {
    Directory directory = Directory(widget.config.path);
    try {
      var files = await directory
          .list()
          .map((event) => event.path)
          .where((element) => !p.basename(element).startsWith("."))
          .take(20)
          .toList();
      return files;
    } catch (e) {
      print(e);
      return [];
    }
  }

  Widget buildFileGridImpl(List<String> data) {
    print(data);
    return SizedBox(
        height: 200,
        child: GridView.count(
          crossAxisCount: 10,
          children: [
            for (var f in data) Text(f),
          ],
        ));
  }
}
