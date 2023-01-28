import 'package:flutter/material.dart';
import 'package:nas2cloud/api/dto/file_upload_record.dart';
import 'package:nas2cloud/api/dto/file_upload_status_enum.dart';
import 'package:nas2cloud/components/uploader/file_uploder.dart';
import 'package:nas2cloud/utils/data_size.dart';
import 'package:nas2cloud/utils/time.dart';

class FileUploadTaskPage extends StatefulWidget {
  @override
  State<FileUploadTaskPage> createState() => _FileUploadTaskPageState();
}

class _FileUploadTaskPageState extends State<FileUploadTaskPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _repeatAniController;

  @override
  void initState() {
    super.initState();
    FileUploader.get().addListener(onUploadChange);
    _repeatAniController = AnimationController(vsync: this)
      ..drive(Tween(begin: 0, end: 1))
      ..duration = Duration(milliseconds: 1000)
      ..repeat();
  }

  @override
  void dispose() {
    FileUploader.get().removeListener(onUploadChange);
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
      actions: [buildMoreMenu()],
    );
  }

  buildMoreMenu() {
    return PopupMenuButton<Text>(
      icon: Icon(Icons.more_horiz),
      itemBuilder: (context) {
        return [
          PopupMenuItem(
            child: Text("清空已完成任务"),
            onTap: () => clearTask([FileUploadStatus.success]),
          ),
          PopupMenuItem(
            child: Text("清空出错任务"),
            onTap: () => clearTask([FileUploadStatus.failed]),
          ),
          PopupMenuItem(
            child: Text("清空所有任务"),
            onTap: () => clearTask([
              FileUploadStatus.success,
              FileUploadStatus.failed,
              FileUploadStatus.waiting
            ]),
          ),
        ];
      },
    );
  }

  clearTask(List<FileUploadStatus> filters) {
    var uploader = FileUploader.get();
    uploader.clearRecordByState(filters);
    setState(() {});
  }

  buildUpladList() {
    var uploader = FileUploader.get();
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
    var uploader = FileUploader.get();
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
      leading: buildLeadingIcon(record.status, record.message),
      title: Text(record.fileName),
      subtitle: Text("$time $size"),
    );
  }

  void onUploadChange(FileUploadRecord record) {
    setState(() {});
  }

  buildLeadingIcon(String stateName, String message) {
    var status = FileUploadStatus.valueOf(stateName);
    if (status == null) {
      return Icon(
        Icons.question_mark,
      );
    }
    switch (status) {
      case FileUploadStatus.failed:
        return Tooltip(
          message: message,
          child: Icon(
            Icons.error_outline,
          ),
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
        );
    }
  }
}
