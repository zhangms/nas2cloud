import 'package:flutter/material.dart';
import 'package:nas2cloud/api/api.dart';
import 'package:nas2cloud/api/dto/file_walk_request.dart';
import 'package:nas2cloud/api/dto/file_walk_response/file.dart';
import 'package:nas2cloud/api/dto/file_walk_response/file_walk_response.dart';
import 'package:nas2cloud/components/files/file_list.dart';
import 'package:nas2cloud/themes/widgets.dart';

class FileHomePage extends StatelessWidget {
  static const _pageSize = 50;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FileWalkResponse>(
        future: walk(),
        builder: (context, snapshot) {
          return SafeArea(child: buildBody(context, snapshot));
        });
  }

  Widget buildBody(
      BuildContext context, AsyncSnapshot<FileWalkResponse> snapshot) {
    if (snapshot.connectionState != ConnectionState.done) {
      return AppWidgets.getPageLoadingView();
    }
    var response = snapshot.data!;
    if (!response.success) {
      return AppWidgets.getPageErrorView(response.message ?? "ERROR");
    }
    var files = response.data?.files ?? [];
    if (files.isEmpty) {
      return AppWidgets.getPageEmptyView();
    }
    return ListView(
      children: [
        for (int i = 0; i < files.length; i++) buildListItem(context, files[i])
      ],
    );
  }

  ListTile buildListItem(BuildContext context, File item) {
    return ListTile(
      leading: buildItemIcon(item),
      title: Text(item.name),
      subtitle: Text("${item.modTime}  ${item.size}"),
      trailing: Icon(Icons.navigate_next),
      onTap: () {
        if (item.type == "DIR") {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => FileListPage(item.path, item.name),
            ),
          );
        }
      },
    );
  }

  Future<FileWalkResponse> walk() async {
    FileWalkRequest request = FileWalkRequest(
        path: "/", pageNo: 0, pageSize: _pageSize, orderBy: "fileName");
    return await Api().postFileWalk(request);
  }

  Widget? buildItemIcon(File item) {
    if (item.type == "DIR") {
      return Icon(Icons.folder);
    }
    return Icon(Icons.insert_drive_file);
  }
}
