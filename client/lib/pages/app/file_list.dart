import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nas2cloud/api/file_walk_response/file.dart';

import '../../api/api.dart';
import '../../api/file_walk_reqeust.dart';
import '../../api/file_walk_response/data.dart' as filewk;

class FileListPage extends StatefulWidget {
  final String path;

  FileListPage(this.path);

  @override
  State<FileListPage> createState() => _FileListPageState();
}

class _FileListPageState extends State<FileListPage> {
  filewk.Data? walkData;

  @override
  void initState() {
    super.initState();
    walk(widget.path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(),
      body: SafeArea(child: Scrollbar(child: buildFileListView())),
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
    );
  }

  buildFileListView() {
    int len = walkData?.files?.length ?? 0;
    return ListView(
      children: [
        for (int i = 0; i < len; i++) buildListItem(walkData!.files![i])
      ],
    );
  }

  Future<void> walk(String path) async {
    FileWalkReqeust reqeust =
        FileWalkReqeust(path: path, pageNo: 0, orderBy: "fileName");
    var resp = await api.postFileWalk(reqeust);
    if (!resp.success) {
      if (resp.message == "RetryLaterAgain") {
        Timer(Duration(seconds: 1), () {
          walk(path);
        });
      }
      print("walk file error:${resp.toString()}");
      return;
    }
    setState(() {
      walkData = resp.data;
    });
  }

  buildListItem(File item) {
    return ListTile(
      leading: buildItemIcon(item),
      title: Text(item.name),
      subtitle: Text("${item.modTime}  ${item.size}"),
      onTap: () {
        print("F");
      },
    );
  }

  buildItemIcon(File item) {
    if (item.type == "DIR") {
      return Icon(Icons.folder);
    }
    return Icon(Icons.insert_drive_file);
  }
}
