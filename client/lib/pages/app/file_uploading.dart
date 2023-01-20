import 'package:flutter/material.dart';

class FileUploadingPage extends StatefulWidget {
  @override
  State<FileUploadingPage> createState() => _FileUploadingPageState();
}

class _FileUploadingPageState extends State<FileUploadingPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(),
      body: Text("uploading"),
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
        "上传列表",
        style: theme.primaryTextTheme.titleMedium,
      ),
    );
  }
}
