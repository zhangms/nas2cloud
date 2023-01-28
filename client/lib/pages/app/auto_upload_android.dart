import 'dart:io';

import 'package:flutter/material.dart';
import 'package:nas2cloud/api/api.dart';
import 'package:nas2cloud/pages/app/file_ext.dart';
import 'package:nas2cloud/themes/widgets.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';

class AndroidAutoUploadConfigWidget extends StatefulWidget {
  @override
  State<AndroidAutoUploadConfigWidget> createState() =>
      _AndroidAutoUploadConfigWidgetState();
}

class _AndroidAutoUploadConfigWidgetState
    extends State<AndroidAutoUploadConfigWidget> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_AndroidAutoUploadConfig>(
        future: getAutoUploadConfig(),
        builder: (context, snapshot) {
          return buildBody(snapshot);
        });
  }

  static const String rootdir = "/storage/emulated/0/";

  Future<_AndroidAutoUploadConfig> getAutoUploadConfig() async {
    if (!await Permission.storage.request().isGranted) {
      return _AndroidAutoUploadConfig(false, []);
    }
    List<_AutoUploadDirConfig> result = [];
    Directory directory = Directory(rootdir);
    var files = directory.listSync();
    for (var f in files) {
      if (await isSupportedAutoUploadDir(f)) {
        result.add(getUploadConfig(f.path));
      }
    }
    result.sort(sortUploadConfig);
    return _AndroidAutoUploadConfig(true, result);
  }

  Widget buildBody(AsyncSnapshot<_AndroidAutoUploadConfig> snapshot) {
    if (!snapshot.hasData) {
      return AppWidgets.getPageLoadingView();
    }
    _AndroidAutoUploadConfig config = snapshot.data!;
    if (!config.storageGrant) {
      return AppWidgets.getPageErrorView("请开启文件访问授权，方可自动上传");
    }
    return ListView(
      children: [
        for (var cfg in config.configs)
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

  viewAutoUploadConfig(_AutoUploadDirConfig cfg) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _AndroidAutoUploadConfigView(cfg),
      ),
    );
  }

  static const List<String> fileNameBlackList = ["android", "miui"];

  Future<bool> isSupportedAutoUploadDir(FileSystemEntity f) async {
    if (!await FileSystemEntity.isDirectory(f.path)) {
      return false;
    }
    var name = p.basename(f.path);
    if (name.startsWith(".")) {
      return false;
    }
    if (fileNameBlackList.contains(name.toLowerCase())) {
      return false;
    }
    return true;
  }

  int sortUploadConfig(_AutoUploadDirConfig a, _AutoUploadDirConfig b) {
    if (a.autoupload && !b.autoupload) {
      return -1;
    }
    if (!a.autoupload && b.autoupload) {
      return 1;
    }
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  }

  _AutoUploadDirConfig getUploadConfig(String path) {
    return _AutoUploadDirConfig(
        name: p.basename(path), path: path, autoupload: false);
  }
}

class _AndroidAutoUploadConfig {
  bool storageGrant = false;
  List<_AutoUploadDirConfig> configs;
  _AndroidAutoUploadConfig(this.storageGrant, this.configs);
}

class _AutoUploadDirConfig {
  final String name;
  final String path;
  String? remote;
  bool autoupload;

  _AutoUploadDirConfig({
    required this.name,
    required this.path,
    required this.autoupload,
    this.remote,
  });

  _AutoUploadDirConfig copyWith({
    String? name,
    String? path,
    String? remote,
    bool? autoupload,
  }) {
    return _AutoUploadDirConfig(
      name: name ?? this.name,
      path: path ?? this.path,
      remote: remote ?? this.remote,
      autoupload: autoupload ?? this.autoupload,
    );
  }
}

class _AndroidAutoUploadConfigView extends StatefulWidget {
  final _AutoUploadDirConfig config;

  _AndroidAutoUploadConfigView(this.config);

  @override
  State<_AndroidAutoUploadConfigView> createState() =>
      _AndroidAutoUploadConfigViewState();
}

class _AndroidAutoUploadConfigViewState
    extends State<_AndroidAutoUploadConfigView> {
  late _AutoUploadDirConfig stateConfig;
  late TextEditingController remoteLocation;
  String? remoteLocationError;

  @override
  void initState() {
    super.initState();
    stateConfig = widget.config.copyWith();
    remoteLocation = TextEditingController(text: stateConfig.remote);
    remoteLocation.addListener(() {
      if (remoteLocation.text.isNotEmpty && remoteLocationError != null) {
        setState(() {
          remoteLocationError = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(stateConfig.name),
        leading: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.close)),
        actions: [
          TextButton(
            onPressed: () => save(),
            child: Text("保存"),
          )
        ],
      ),
      body: buildBody(),
    );
  }

  Future<void> save() async {
    if (remoteLocation.text.isEmpty) {
      setState(() {
        remoteLocationError = "请输入";
      });
      return;
    }
    var result = await Api.getFileExists(remoteLocation.text);
    if (result.message != "true") {
      setState(() {
        remoteLocationError = "远程目录不存在：首页文件列表->more->显示当前位置";
      });
      return;
    }
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
                ? InputDecoration(
                    errorText: remoteLocationError,
                  )
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
          .where((element) {
            var name = p.basename(element);
            return !name.startsWith(".");
          })
          .take(30)
          .toList();
      return files;
    } catch (e) {
      print(e);
      return [];
    }
  }

  Widget buildFileGridImpl(List<String> data) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: SizedBox(
          height: 500,
          child: GridView.count(
            crossAxisCount: 4,
            children: [
              for (var path in data) buildItemCard(path),
            ],
          )),
    );
  }

  Widget buildItemCard(String path) {
    var theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SizedBox(
        height: 300,
        width: 300,
        child: FutureBuilder<Widget>(
            future: buildFileThumbWidget(path, theme),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return snapshot.data!;
              }
              return Text("");
            }),
      ),
    );
  }

  Future<Widget> buildFileThumbWidget(String path, ThemeData theme) async {
    if (await FileSystemEntity.isDirectory(path)) {
      return buildItemThumbIcon(Icons.folder, path, theme);
    }
    if (FileExt.isImage(p.extension(path).toUpperCase())) {
      return Image.file(File(path));
    }
    if (FileExt.isVideo(p.extension(path).toUpperCase())) {
      return buildItemThumbIcon(Icons.video_file, path, theme);
    }
    return buildItemThumbIcon(Icons.insert_drive_file, path, theme);
  }

  Widget buildItemThumbIcon(IconData icon, String path, ThemeData theme) {
    return Stack(
      alignment: AlignmentDirectional.bottomCenter,
      children: [
        Icon(
          icon,
          size: 100,
        ),
        Container(
          margin: EdgeInsets.all(8),
          child: Text(
            p.basename(path),
            style: TextStyle(
                fontSize: 12,
                overflow: TextOverflow.ellipsis,
                color: theme.colorScheme.onPrimary),
          ),
        ),
      ],
    );
  }
}
