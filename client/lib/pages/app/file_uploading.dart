import 'package:flutter/material.dart';
import 'package:nas2cloud/api/dto/file_upload_record.dart';
import 'package:nas2cloud/api/dto/file_upload_status_enum.dart';
import 'package:nas2cloud/api/uploader/file_uploder.dart';
import 'package:nas2cloud/utils/data_size.dart';
import 'package:nas2cloud/utils/time.dart';

class FileUploadingPage extends StatefulWidget {
  @override
  State<FileUploadingPage> createState() => _FileUploadingPageState();
}

class _FileUploadingPageState extends State<FileUploadingPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _repeatAniController;

  @override
  void initState() {
    super.initState();
    FileUploader.getInstance().addListener(onUploadChange);
    _repeatAniController = AnimationController(vsync: this)
      ..drive(Tween(begin: 0, end: 1))
      ..duration = Duration(milliseconds: 1000)
      ..repeat();
  }

  @override
  void dispose() {
    FileUploader.getInstance().removeListener(onUploadChange);
    _repeatAniController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(),
      body: buildUpladList(),
    );
  }

  buildAppBar() {
    var theme = Theme.of(context);
    return AppBar(
      backgroundColor: theme.primaryColor,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back,
          color: theme.primaryIconTheme.color,
        ),
        onPressed: () {
          Navigator.of(context).pop();
        },
      ),
      title: Text(
        "文件上传任务",
        style: theme.primaryTextTheme.titleMedium,
      ),
      actions: [buildMoreMenu(theme)],
    );
  }

  buildMoreMenu(ThemeData theme) {
    return PopupMenuButton<Text>(
      icon: Icon(
        Icons.more_horiz,
        color: theme.primaryIconTheme.color,
      ),
      itemBuilder: (context) {
        return [
          PopupMenuItem(
            child: Text("清空已完成任务"),
            onTap: () => clearTask([FileUploadStatus.success]),
          ),
          PopupMenuItem(
            child: Text("清空出错任务"),
            onTap: () => clearTask([FileUploadStatus.error]),
          ),
          PopupMenuItem(
            child: Text("清空所有任务"),
            onTap: () => clearTask([
              FileUploadStatus.success,
              FileUploadStatus.error,
              FileUploadStatus.waiting
            ]),
          ),
        ];
      },
    );
  }

  clearTask(List<FileUploadStatus> filters) {
    var uploader = FileUploader.getInstance();
    uploader.clearRecordByState(filters);
    setState(() {});
  }

  buildUpladList() {
    var uploader = FileUploader.getInstance();
    int total = uploader.getCount();

    if (total <= 0) {
      return Center(
        child: Text("无任务"),
      );
    }
    return ListView.builder(
        itemCount: total >= 0 ? total : 0,
        itemBuilder: ((context, index) {
          return buildItemView(index);
        }));
  }

  buildItemView(int index) {
    var uploader = FileUploader.getInstance();
    FileUploadRecord? record = uploader.getRecord(index);
    if (record == null) {
      return ListTile(
        leading: Icon(Icons.question_mark),
        title: Text(""),
        subtitle: Text(""),
      );
    }
    var size = readableDataSize(record.size.toDouble());
    var time = formDateTime(
        DateTime.fromMillisecondsSinceEpoch(record.beginUploadTime));
    return ListTile(
      leading: buildLeadingIcon(record.status),
      title: Text(record.fileName),
      subtitle: Text("$time $size ${record.message}"),
    );
  }

  void onUploadChange(FileUploadRecord record) {
    setState(() {});
  }

  buildLeadingIcon(String stateName) {
    var status = FileUploadStatus.valueOf(stateName);
    if (status == null) {
      return Icon(
        Icons.question_mark,
      );
    }
    switch (status) {
      case FileUploadStatus.error:
        return Icon(
          Icons.error_outline,
          color: Colors.red,
        );
      case FileUploadStatus.waiting:
      case FileUploadStatus.uploading:
        return RotationTransition(
          turns: _repeatAniController,
          child: Icon(Icons.autorenew),
        );
      case FileUploadStatus.success:
        return Icon(
          Icons.done,
          color: Colors.green,
        );
    }
  }
}
