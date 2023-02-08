import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../api/api.dart';
import '../../api/dto/result.dart';
import '../../event/bus.dart';
import '../../themes/app_nav.dart';
import '../../themes/widgets.dart';
import '../uploader/file_uploder.dart';
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
    return PopupMenuButton<Text>(
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
            child: Text("文件上传任务列表"),
            onTap: () => openUploadTaskPage(),
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
    AppWidgets.clearMessage(context);
    AppNav.openPage(context, page);
  }

  void pop() {
    AppWidgets.clearMessage(context);
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
              pop();
            }),
            child: Text("取消")),
        TextButton(
            onPressed: (() {
              createFolder(input.text);
              pop();
            }),
            child: Text("确定"))
      ],
    );
  }

  Future<void> createFolder(String floderName) async {
    if (floderName.trim().isEmpty) {
      return;
    }
    Result result =
        await Api().postCreateFolder(widget.currentPath, floderName);
    if (!result.success) {
      if (mounted) {
        AppWidgets.showMessage(context, result.message!);
      }
      return;
    }
    eventBus.fire(FileEvent(
      type: FileEventType.createFloder,
      currentPath: widget.currentPath,
      source: floderName,
    ));
  }
}
