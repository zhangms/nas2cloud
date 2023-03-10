import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../api/api.dart';
import '../../dto/result.dart';
import '../../event/bus.dart';
import '../../pub/app_message.dart';
import '../../pub/app_nav.dart';
import '../uploader/file_uploader.dart';
import '../uploader/pages/page_file_upload_task.dart';
import 'file_event.dart';

class FileAddMenu extends StatefulWidget {
  final String currentPath;

  FileAddMenu(this.currentPath);

  @override
  State<FileAddMenu> createState() => _FileAddMenuState();
}

class _FileAddMenuState extends State<FileAddMenu> {
  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.add,
      ),
      itemBuilder: (context) {
        return [
          PopupMenuItem(
            child: Text("添加文件"),
            onTap: () => onTabAddFile(),
          ),
          PopupMenuItem(
            child: Text("创建文件夹"),
            onTap: () => onTabCreateFolder(),
          ),
          PopupMenuDivider(),
          PopupMenuItem(
            child: Text("上传任务列表"),
            onTap: () => openUploadTaskPage(),
          ),
          PopupMenuItem(
            onTap: (() => showCurrentPath(context)),
            child: Text("显示当前位置"),
          ),
          PopupMenuItem(
            onTap: () => AppNav.gohome(context),
            child: Text("回到首页"),
          ),
        ];
      },
    );
  }

  onTabAddFile() {
    Future.delayed(const Duration(milliseconds: 100), (() {
      if (kIsWeb) {
        webUpload();
      } else {
        nativeUpload();
      }
    }));
  }

  onTabCreateFolder() async {
    Future.delayed(const Duration(milliseconds: 100), (() {
      showDialog(
          context: context,
          builder: ((context) => buildCreateFolderDialog(context)));
    }));
  }

  openUploadTaskPage() {
    Future.delayed(const Duration(milliseconds: 100), (() {
      openNewPage(FileUploadTaskPage());
    }));
  }

  Future<void> webUpload() async {
    FilePickerResult? result = await FilePicker.platform
        .pickFiles(allowMultiple: true, withData: false, withReadStream: true);
    if (result == null) {
      return;
    }
    for (var i = 0; i < result.files.length; i++) {
      var e = result.files[i];
      print(e);
      if (e.readStream == null) {
        continue;
      }
      FileUploader.platform.uploadStream(
        dest: widget.currentPath,
        fileName: e.name,
        fileSize: e.size,
        stream: e.readStream!,
      );
    }
    openNewPage(FileUploadTaskPage());
  }

  Future<void> nativeUpload() async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result == null) {
      return;
    }
    for (var i = 0; i < result.paths.length; i++) {
      var path = result.paths[i];
      print(path);
      FileUploader.platform.uploadPath(src: path!, dest: widget.currentPath);
    }
    openNewPage(FileUploadTaskPage());
  }

  void openNewPage(Widget page) {
    AppMessage.clear(context);
    AppNav.openPage(context, page);
  }

  void pop() {
    AppMessage.clear(context);
    AppNav.pop(context);
  }

  buildCreateFolderDialog(BuildContext context) {
    var input = TextEditingController();
    return AlertDialog(
      title: Text("创建文件夹"),
      content: TextField(
        controller: input,
        decoration: InputDecoration(
          labelText: "请输入文件夹名称",
        ),
      ),
      actions: [
        TextButton(
            onPressed: (() {
              input.dispose();
              pop();
            }),
            child: Text("取消")),
        TextButton(
            onPressed: (() {
              var name = input.text;
              input.dispose();
              createFolder(name);
              pop();
            }),
            child: Text("确定"))
      ],
    );
  }

  Future<void> createFolder(String folderName) async {
    if (folderName.trim().isEmpty) {
      return;
    }
    Result result =
        await Api().postCreateFolder(widget.currentPath, folderName);
    if (!result.success) {
      if (mounted) {
        AppMessage.show(context, result.message!);
      }
      return;
    }
    eventBus.fire(FileEvent(
      type: FileEventType.createFolder,
      currentPath: widget.currentPath,
      source: folderName,
    ));
  }

  void showCurrentPath(BuildContext context) {
    Future.delayed(Duration(milliseconds: 10), () {
      showDialog(
          context: context,
          builder: ((context) {
            return AlertDialog(
              title: Text("当前位置"),
              content: SelectableText(widget.currentPath),
            );
          }));
    });
  }
}
