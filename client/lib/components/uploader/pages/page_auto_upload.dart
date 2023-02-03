import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nas2cloud/components/background/background.dart';
import 'package:nas2cloud/components/uploader/pages/page_file_upload_task.dart';
import 'package:nas2cloud/themes/app_nav.dart';
import 'package:nas2cloud/themes/widgets.dart';

import 'page_auto_upload_android.dart';

class AutoUploadPage extends StatefulWidget {
  @override
  State<AutoUploadPage> createState() => _AutoUploadPageState();
}

class _AutoUploadPageState extends State<AutoUploadPage> {
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
        onPressed: () => AppNav.pop(context),
      ),
      title: Text("自动上传"),
      actions: [buildMoreMenu()],
    );
  }

  Widget buildBody() {
    if (kIsWeb) {
      return AppWidgets.getPageErrorView("浏览器下无法自动上传");
    }
    if (Platform.isAndroid) {
      return AndroidAutoUploadConfigWidget();
    }
    return AppWidgets.getPageErrorView(
        "尚未支持：${Platform.operatingSystem},${Platform.operatingSystemVersion}");
  }

  PopupMenuButton<Text> buildMoreMenu() {
    return PopupMenuButton<Text>(
      icon: Icon(
        Icons.more_horiz,
      ),
      itemBuilder: (context) {
        return [
          PopupMenuItem(
            child: Text("文件上传任务列表"),
            onTap: () => openUploadTaskPage(),
          ),
          PopupMenuItem(
            child: Text("执行同步"),
            onTap: () => executeUpload(),
          ),
        ];
      },
    );
  }

  openUploadTaskPage() {
    Future.delayed(const Duration(milliseconds: 100), (() {
      AppNav.openPage(context, FileUploadTaskPage());
    }));
  }

  executeUpload() async {
    await BackgroundProcessor().executeOnceAutoUploadTask();
  }
}
