import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nas2cloud/api/file_walk_request.dart';
import 'package:nas2cloud/api/file_walk_response/file.dart';

import '../../api/api.dart';
import '../../app.dart';

const _pageSize = 50;

class FileListPage extends StatefulWidget {
  final String path;
  final String name;

  FileListPage(this.path, this.name);

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
    return Scrollbar(child: buildFileView());
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
          widget.name,
          style: theme.primaryTextTheme.titleMedium,
        ));
  }

  Widget buildFileView() {
    if (total == null) {
      return Center(
        child: Text("Loading..."),
      );
    }
    if (total == 0) {
      return Center(
        child: Text("Empty"),
      );
    }
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
    currentStop = data.currentStop;
    currentPage++;
    items.addAll(data.files ?? []);
    setState(() {
      total = data.total;
    });
  }

  buildListItem(int index) {
    if (items.length - index < 20) {
      fetchNext(widget.path);
    }
    if (items.length <= index) {
      return ListTile(
        leading: Icon(Icons.hourglass_empty),
      );
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
              builder: (context) => FileListPage(item.path, item.name),
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
          height: 40,
          width: 40,
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