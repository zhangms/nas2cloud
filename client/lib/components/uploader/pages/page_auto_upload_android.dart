import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';

import '../../../api/api.dart';
import '../../../event/bus.dart';
import '../event_fileupload.dart';
import '../../../pub/app_nav.dart';
import '../../../pub/widgets.dart';
import '../auto_upload_config.dart';
import '../auto_uploader.dart';
import '../upload_repo.dart';
import '../upload_status.dart';
import 'local_file_grid_view.dart';

class AndroidAutoUploadConfigWidget extends StatefulWidget {
  @override
  State<AndroidAutoUploadConfigWidget> createState() =>
      _AndroidAutoUploadConfigWidgetState();
}

class _AndroidAutoUploadConfigWidgetState
    extends State<AndroidAutoUploadConfigWidget> {
  late StreamSubscription<EventFileUpload> uploadSubscription;

  @override
  void initState() {
    super.initState();
    uploadSubscription = eventBus.on<EventFileUpload>().listen((event) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    super.dispose();
    uploadSubscription.cancel();
  }

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
          .countByChannel(channel: config.uploadChannel);
      int complete = await UploadRepository.platform.countByChannel(
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
      return AppWidgets.pageLoadingView();
    }
    _AndroidAutoUploadConfig config = snapshot.data!;
    if (!config.storageGrant) {
      return AppWidgets.pageErrorView("请开启文件访问授权，方可自动上传");
    }
    return ListView(
      children: [
        buildAutoUploadSetting(),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Divider(),
        ),
        for (var cfg in config.configs)
          ListTile(
            leading: getConfigLeading(cfg),
            trailing: Icon(Icons.navigate_next),
            title: Text(cfg.name),
            subtitle: getConfigDiscripeWidget(cfg),
            onTap: () => showConfig(cfg),
          ),
      ],
    );
  }

  buildAutoUploadSetting() {
    return ListTile(
      title: Text("仅WLAN下自动上传"),
      trailing: FutureBuilder<bool>(
          future: AutoUploader.getAutouploadWlanSetting(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Text("");
            }
            return Switch(
                value: snapshot.data!,
                onChanged: (value) {
                  AutoUploader.setAutouploadWlanSetting(value);
                  setState(() {});
                });
          }),
    );
  }

  showConfig(_AutoUploadConfigWrapper cfg) {
    AppNav.openPage(context, _ConfigView(cfg.config, onSave));
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

  Widget? getConfigDiscripeWidget(_AutoUploadConfigWrapper cfg) {
    if (!cfg.autoupload || (cfg.total ?? 0) == 0) {
      if (cfg.remote == null) {
        return null;
      }
      return Text(cfg.remote!);
    }
    return Text("${cfg.remote} (${cfg.complete}/${cfg.total})");
  }

  Widget getConfigLeading(_AutoUploadConfigWrapper cfg) {
    if (!cfg.autoupload) {
      return Icon(Icons.cloud_off);
    }
    var total = cfg.total ?? -1;
    var complete = cfg.complete ?? -1;
    if (total > 0 && total != complete) {
      return Icon(Icons.cloud_upload);
    }
    if (total > 0 && total == complete) {
      return Icon(Icons.cloud_done);
    }
    return Icon(Icons.cloud);
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
            onPressed: () => AppNav.pop(context), icon: Icon(Icons.close)),
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
      AppNav.pop(context);
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
