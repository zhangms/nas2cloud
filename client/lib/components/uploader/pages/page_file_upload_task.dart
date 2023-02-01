import 'package:flutter/material.dart';
import 'package:nas2cloud/api/dto/page_data.dart';
import 'package:nas2cloud/components/uploader/file_uploder.dart';
import 'package:nas2cloud/components/uploader/upload_entry.dart';
import 'package:nas2cloud/components/uploader/upload_repo.dart';
import 'package:nas2cloud/components/uploader/upload_status.dart';
import 'package:nas2cloud/themes/widgets.dart';
import 'package:nas2cloud/utils/data_size.dart';
import 'package:path/path.dart' as p;

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

  @override
  void initState() {
    super.initState();
    FileUploader.addListener(onUploadStatusChange);
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
    FileUploader.removeListener(onUploadStatusChange);
    _tabController.dispose();
    super.dispose();
  }

  onUploadStatusChange(UploadEntry entry) {
    setState(() {});
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
          Navigator.of(context).pop();
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
            child: Text("取消并清空所有任务"),
            onTap: () => cancelAll(),
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
            return AppWidgets.getPageLoadingView();
          }
          var page = snapshot.data!;
          if (page.data.isEmpty) {
            return AppWidgets.getCenterTextView("无任务");
          }
          return ListView.builder(
              itemCount: page.total,
              itemBuilder: ((context, index) {
                return buildItemView(index, page.data[index]);
              }));
        });
  }

  buildItemView(int index, UploadEntry data) {
    return ListTile(
      leading: buildLeadingIcon(data),
      title: Text(p.basename(data.src)),
      subtitle: Text(summary(data)),
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
        return AppWidgets.getRepeatRotation(Icon(Icons.autorenew), 1000);
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

  clearTask(UploadStatus status) {
    FileUploader.platform.clearTask(status);
    setState(() {});
  }

  cancelAll() {
    FileUploader.platform.cancelAndClearAll();
    setState(() {});
  }
}
