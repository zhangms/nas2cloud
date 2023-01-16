import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nas2cloud/api/file_walk_request.dart';
import 'package:nas2cloud/api/file_walk_response/file.dart';

import '../../api/api.dart';
import '../../app.dart';

const _pageSize = 50;

class FileListPage extends StatefulWidget {
  final String path;

  FileListPage(this.path);

  @override
  State<FileListPage> createState() => _FileListPageState();
}

class _FileListPageState extends State<FileListPage> {
  int? total;
  int currentStop = 0;
  int currentPage = -1;
  List<File> items = [];
  bool fetching = false;

  @override
  void initState() {
    super.initState();
    fetchNext(widget.path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(),
      body: SafeArea(child: buildScrollbar()),
    );
  }

  Widget buildScrollbar() {
    return NotificationListener<ScrollNotification>(
        onNotification: ((ScrollNotification notification) {
          if (notification.metrics.pixels ==
              notification.metrics.maxScrollExtent) {
            print("max");
          }
          return true;
        }),
        child: buildFileListView());
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
    return ListView.builder(
        itemCount: total ?? 0,
        itemBuilder: ((context, index) {
          return buildListItem(index);
        }));
  }

  fetchNext(String path) async {
    if (total != null && currentStop >= total!) {
      return;
    }
    if (fetching) {
      return;
    }
    fetching = true;
    FileWalkRequest request = FileWalkRequest(
        path: path,
        pageNo: currentPage + 1,
        pageSize: _pageSize,
        orderBy: "fileName");
    var resp = await api.postFileWalk(request);
    fetching = false;
    if (!resp.success) {
      if (resp.message == "RetryLaterAgain") {
        Timer(Duration(milliseconds: 100), () {
          fetchNext(path);
        });
        print("fetchNext RetryLaterAgain");
        return;
      }
      print("fetchNext error:${resp.toString()}");
      return;
    }
    var data = resp.data!;
    var stop = data.currentStop;
    items.addAll(data.files ?? []);
    setState(() {
      total = data.total;
      currentPage = currentPage + 1;
      currentStop = stop;
    });
  }

  buildListItem(int index) {
    if (items.length - index < 20) {
      fetchNext(widget.path);
    }
    if (items.length <= index) {
      return Text("");
    }
    var item = items[index];
    return ListTile(
      leading: buildItemIcon(item),
      title: Text(item.name),
      subtitle: Text("${item.modTime}  ${item.size}"),
      onTap: () {
        if (item.type == "DIR") {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => FileListPage(item.path),
            ),
          );
        }
      },
    );
  }

  buildItemIcon(File item) {
    if (item.type == "DIR") {
      return Icon(Icons.folder);
    }
    if (item.thumbnail != null && item.thumbnail!.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 5, bottom: 5),
        child: SizedBox(
          height: 50,
          width: 50,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: Image.network(
              appStorage.getStaticFileUrl(item.thumbnail!),
              headers: api.httpHeaders(),
            ),
          ),
        ),
      );
    }
    return Icon(Icons.insert_drive_file);
  }
}
