import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nas2cloud/api/api.dart';
import 'package:nas2cloud/api/file_walk_request.dart';
import 'package:nas2cloud/api/file_walk_response/file.dart';
import 'package:nas2cloud/app.dart';

const _pageSize = 50;

const orderByOptions = [
  {"orderBy": "fileName", "name": "文件名排序"},
  {"orderBy": "size_asc", "name": "文件大小正序"},
  {"orderBy": "size_desc", "name": "文件大小倒序"},
  {"orderBy": "modTime_asc", "name": "修改时间正序"},
  {"orderBy": "modTime_desc", "name": "修改时间倒序"},
  {"orderBy": "creTime_desc", "name": "最新添加"},
];

class FileListPage extends StatefulWidget {
  final String path;
  final String name;

  FileListPage(this.path, this.name);

  @override
  State<FileListPage> createState() => _FileListPageState();
}

class _FileListPageState extends State<FileListPage> {
  late int total;
  late int currentStop;
  late int currentPage;
  late List<File> items;
  late bool fetching;
  late String orderBy;

  @override
  void initState() {
    super.initState();
    setInitState();
    fetchNext(widget.path);
  }

  void setInitState() {
    total = -1;
    currentStop = -1;
    currentPage = -1;
    fetching = false;
    items = [];
    orderBy = orderByOptions[0]["orderBy"]!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(),
      body: SafeArea(child: buildBodyView()),
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
        widget.name,
        style: theme.primaryTextTheme.titleMedium,
      ),
      actions: [
        PopupMenuButton<Text>(
          icon: Icon(
            Icons.add,
            color: theme.primaryIconTheme.color,
          ),
          itemBuilder: (context) {
            return [
              PopupMenuItem(
                child: Text("添加文件"),
              ),
              PopupMenuItem(
                child: Text("创建文件夹"),
              )
            ];
          },
        ),
        PopupMenuButton<Text>(
          icon: Icon(
            Icons.more_horiz,
            color: theme.primaryIconTheme.color,
          ),
          color: theme.primaryIconTheme.color,
          itemBuilder: (context) {
            return [
              PopupMenuItem(
                enabled: false,
                child: Text("排序方式"),
              ),
              PopupMenuDivider(),
              for (var i = 0; i < orderByOptions.length; i++)
                PopupMenuItem(
                  enabled: orderByOptions[i]["orderBy"]! != orderBy,
                  child: Text(orderByOptions[i]["name"]!),
                  onTap: () => changeOrderBy(orderByOptions[i]["orderBy"]!),
                )
            ];
          },
        )
      ],
    );
  }

  changeOrderBy(String order) {
    if (orderBy == order) {
      return;
    }
    setInitState();
    setState(() {
      orderBy = order;
    });
    fetchNext(widget.path);
  }

  Widget buildBodyView() {
    if (total <= 0) {
      return Center(
        child: Text(total < 0 ? "Loading" : "Empty"),
      );
    }
    return ListView.builder(
        itemCount: total >= 0 ? total : 0,
        itemBuilder: ((context, index) {
          return buildItemView(index);
        }));
  }

  fetchNext(String path) async {
    if (fetching || (total >= 0 && currentStop >= total)) {
      return;
    }
    try {
      fetching = true;
      FileWalkRequest request = FileWalkRequest(
          path: path,
          pageNo: currentPage + 1,
          pageSize: _pageSize,
          orderBy: orderBy);
      var resp = await api.postFileWalk(request);
      if (!resp.success && resp.message == "RetryLaterAgain") {
        Timer(Duration(milliseconds: 100), () => fetchNext(path));
        print("fetchNext RetryLaterAgain");
        return;
      } else if (!resp.success) {
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
    } finally {
      fetching = false;
    }
  }

  buildItemView(int index) {
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
        onItemTap(item);
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

  void onItemTap(File item) {
    if (item.type == "DIR") {
      openNewFileListPage(item.path, item.name);
    }
  }

  void openNewFileListPage(String path, String name) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FileListPage(path, name),
      ),
    );
  }
}
