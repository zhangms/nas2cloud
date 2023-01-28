import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nas2cloud/themes/widgets.dart';

import 'auto_upload_android.dart';

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
        onPressed: () {
          Navigator.of(context).pop();
        },
      ),
      title: Text("自动上传"),
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
}
