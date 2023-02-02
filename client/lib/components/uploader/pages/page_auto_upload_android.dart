import 'dart:io';

import 'package:flutter/material.dart';
import 'package:nas2cloud/api/api.dart';
import 'package:nas2cloud/api/app_config.dart';
import 'package:nas2cloud/components/uploader/auto_upload_config.dart';
import 'package:nas2cloud/components/uploader/auto_uploader.dart';
import 'package:nas2cloud/components/uploader/pages/local_file_grid_view.dart';
import 'package:nas2cloud/components/uploader/upload_repo.dart';
import 'package:nas2cloud/components/uploader/upload_status.dart';
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

  static const String rootdir = "/storage/emulated/0";

  Future<_AndroidAutoUploadConfig> getAutoUploadConfig() async {
    if (!await Permission.manageExternalStorage.request().isGranted) {
      return _AndroidAutoUploadConfig(false, []);
    }

    Directory directory = Directory(rootdir);
    var files = directory.listSync();
    Map<String, _AutoUploadConfigWrapper> configMap = {};
    for (var config in await AutoUploader().getConfigList()) {
      int total = await UploadRepository.platform
          .findCountByChannel(channel: config.uploadChannel);
      int complete = await UploadRepository.platform.findCountByChannel(
          channel: config.uploadChannel,
          status: [UploadStatus.successed.name, UploadStatus.failed.name]);
      configMap[config.path] = _AutoUploadConfigWrapper(
          config: config, total: total, complete: complete);
    }
    List<_AutoUploadConfigWrapper> result = [];
    for (var f in files) {
      if (await isSupportedAutoUploadDir(f)) {
        var cfg = configMap[f.path] ??
            _AutoUploadConfigWrapper(
                config: AutoUploadConfig(
                    basepath: rootdir,
                    name: p.basename(f.path),
                    path: f.path,
                    autoupload: false));
        result.add(cfg);
      }
    }
    result.sort(configSorter);
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
        buildAutoUploadSetting(),
        for (var cfg in config.configs)
          ListTile(
            leading: cfg.autoupload ? Icon(Icons.cloud) : Icon(Icons.cloud_off),
            trailing: Icon(Icons.navigate_next),
            title: Text(cfg.name),
            subtitle: cfg.description != null ? Text(cfg.description!) : null,
            onTap: () => showConfig(cfg),
          ),
      ],
    );
  }

  buildAutoUploadSetting() {
    return ListTile(
      title: Text("仅WLAN下自动上传"),
      trailing: FutureBuilder<bool>(
          future: AppConfig.getAutouploadWlanSetting(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Text("");
            }
            return Switch(
                value: snapshot.data!,
                onChanged: (value) {
                  AppConfig.setAutouploadWlanSetting(value);
                  setState(() {});
                });
          }),
    );
  }

  showConfig(_AutoUploadConfigWrapper cfg) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _ConfigView(cfg.config, onSave),
      ),
    );
  }

  onSave(AutoUploadConfig config) async {
    await AutoUploader().saveConfig(config);
    setState(() {});
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

  int configSorter(_AutoUploadConfigWrapper a, b) {
    if (a.autoupload && !b.autoupload) {
      return -1;
    }
    if (!a.autoupload && b.autoupload) {
      return 1;
    }
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  }
}

class _AndroidAutoUploadConfig {
  bool storageGrant = false;
  List<_AutoUploadConfigWrapper> configs;
  _AndroidAutoUploadConfig(this.storageGrant, this.configs);
}

class _AutoUploadConfigWrapper {
  AutoUploadConfig config;
  int? total;
  int? complete;

  String get name => config.name;
  String get path => config.path;
  String get basepath => config.basepath;
  String? get remote => config.remote;
  bool get autoupload => config.autoupload;

  _AutoUploadConfigWrapper({required this.config, this.total, this.complete});

  String? get description {
    if (!autoupload) {
      return remote;
    }
    if ((total ?? 0) > 0) {
      return "$remote ($complete/$total)";
    }
    return remote;
  }
}

class _ConfigView extends StatefulWidget {
  final AutoUploadConfig config;

  final Function(AutoUploadConfig config) save;

  _ConfigView(this.config, this.save);

  @override
  State<_ConfigView> createState() => _ConfigViewState();
}

class _ConfigViewState extends State<_ConfigView> {
  late AutoUploadConfig stateConfig;
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
        actions: [IconButton(onPressed: () => save(), icon: Icon(Icons.done))],
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
    var result = await Api().getFileExists(remoteLocation.text);
    if (result.message != "true") {
      setState(() {
        remoteLocationError = "远程目录不存在：首页文件列表->more->显示当前位置";
      });
      return;
    }
    stateConfig.remote = remoteLocation.text;
    widget.save(stateConfig);
    setState(() {
      Navigator.of(context).pop();
    });
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
        SizedBox(
          height: 500,
          child: LocalDirListGridView(widget.config.path, 30),
        )
      ],
    );
  }
}
