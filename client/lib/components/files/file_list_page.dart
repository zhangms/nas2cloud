import 'package:flutter/material.dart';
import 'package:nas2cloud/components/files/file_menu_orderby.dart';

import '../../pub/widgets.dart';
import 'file_list_view.dart';
import 'file_menu_add.dart';
import 'file_menu_more.dart';

class FileListPage extends StatelessWidget {
  final String path;
  final String name;

  FileListPage(this.path, this.name);

  @override
  Widget build(BuildContext context) {
    String initOrderBy = "modTime_desc";
    int pageSize = 50;
    return Scaffold(
      appBar: AppBar(
        leading: AppWidgets.appBarArrowBack(context),
        title: Text(name),
        actions: [
          FileAddMenu(path),
          FileOrderByMenu(path, initOrderBy),
          FileMoreMenu(path)
        ],
      ),
      body: SafeArea(
          child: FileListView(
        path: path,
        pageSize: pageSize,
        orderByInitValue: initOrderBy,
        fileHome: false,
      )),
    );
  }
}
