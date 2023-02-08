import 'dart:async';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../../../api/dto/page_data.dart';
import '../../../event/bus.dart';
import '../../../event/event_fileupload.dart';
import '../../../themes/app_nav.dart';
import '../../../themes/widgets.dart';
import '../../../utils/data_size.dart';
import '../file_uploder.dart';
import '../upload_entry.dart';
import '../upload_repo.dart';
import '../upload_status.dart';

class FileUploadTaskPage extends StatefulWidget {
  @override
  State<FileUploadTaskPage> createState() => _FileUploadTaskPageState();
}

final _tabs = [
  {
    "name": "上传中",
    "state": UploadStatus.uploading.name,
  },
  {
    "name": "等待上传",
    "state": UploadStatus.waiting.name,
  },
  {
    "name": "上传成功",
    "state": UploadStatus.successed.name,
  },
  {
    "name": "上传失败",
    "state": UploadStatus.failed.name,
  }
];

class _FileUploadTaskPageState extends State<FileUploadTaskPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  late StreamSubscription<EventFileUpload> uploadSubscription;

  @override
  void initState() {
    super.initState();
    uploadSubscription = eventBus.on<EventFileUpload>().listen((event) {
      setState(() {});
    });
    _tabController = TabController(
      initialIndex: 0,
      length: _tabs.length,
      vsync: this,
    );
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    uploadSubscription.cancel();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(),
      body: buildBody(),
    );
  }

  buildAppBar() {
    return AppBar(
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back,
        ),
        onPressed: () {
          AppNav.pop(context);
        },
      ),
      title: Text("文件上传任务"),
      bottom: TabBar(
        controller: _tabController,
        tabs: [
          for (var tab in _tabs)
            Tab(
              text: tab["name"]!,
            )
        ],
      ),
      actions: [buildMoreMenu()],
    );
  }

  buildMoreMenu() {
    return PopupMenuButton<Text>(
      icon: Icon(Icons.more_horiz),
      itemBuilder: (context) {
        return [
          PopupMenuItem(
            child: Text("清空成功任务"),
            onTap: () => clearTask(UploadStatus.successed),
          ),
          PopupMenuItem(
            child: Text("清空失败任务"),
            onTap: () => clearTask(UploadStatus.failed),
          ),
          PopupMenuItem(
            child: Text("取消上传"),
            onTap: () => cancelAllRunning(),
          ),
        ];
      },
    );
  }

  buildBody() {
    return TabBarView(
      controller: _tabController,
      children: [for (var tab in _tabs) buildUploadList(tab["state"]!)],
    );
  }

  Widget buildUploadList(String taskState) {
    return FutureBuilder<PageData<UploadEntry>>(
        future: UploadRepository.platform.findByStatus(
          status: taskState,
          page: 0,
          pageSize: 100,
        ),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return AppWidgets.pageLoadingView();
          }
          var page = snapshot.data!;
          if (page.data.isEmpty) {
            return AppWidgets.centerTextView("无任务");
          }
          return ListView.builder(
              itemCount: page.data.length,
              itemBuilder: ((context, index) {
                return buildItemView(page.data[index]);
              }));
        });
  }

  buildItemView(UploadEntry entry) {
    return ListTile(
      leading: buildLeadingIcon(entry),
      title: Text(p.basename(entry.src)),
      subtitle: Text(summary(entry)),
    );
  }

  String summary(UploadEntry data) {
    var uploadTime = "-";
    if (data.endUploadTime > 0) {
      uploadTime =
          DateTime.fromMillisecondsSinceEpoch(data.endUploadTime).toString();
    } else if (data.beginUploadTime > 0) {
      uploadTime =
          DateTime.fromMillisecondsSinceEpoch(data.beginUploadTime).toString();
    } else if (data.createTime > 0) {
      uploadTime =
          DateTime.fromMillisecondsSinceEpoch(data.createTime).toString();
    }
    return "$uploadTime ${readableDataSize(data.size.toDouble())}";
  }

  buildLeadingIcon(UploadEntry entry) {
    var uploadState = UploadStatus.valueOf(entry.status);
    if (uploadState == null) {
      return Icon(Icons.question_mark);
    }
    switch (uploadState) {
      case UploadStatus.waiting:
        return Icon(Icons.pending);
      case UploadStatus.uploading:
        return AppWidgets.repeatRotation(Icon(Icons.autorenew), 1000);
      case UploadStatus.successed:
        return Icon(Icons.done);
      case UploadStatus.failed:
        return Tooltip(
          message: entry.message,
          child: Icon(Icons.error_outline),
        );
      default:
    }
  }

  clearTask(UploadStatus status) async {
    await FileUploader.platform.clearTask(status);
    setState(() {});
  }

  cancelAllRunning() async {
    await FileUploader.platform.cancelAllRunning();
    setState(() {});
  }
}
