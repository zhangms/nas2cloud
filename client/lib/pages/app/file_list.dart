import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nas2cloud/api/api.dart';
import 'package:nas2cloud/api/file_walk_request.dart';
import 'package:nas2cloud/api/file_walk_response/file.dart';
import 'package:nas2cloud/api/result.dart';
import 'package:nas2cloud/app.dart';
import 'package:nas2cloud/pages/app/gallery.dart';

const _pageSize = 50;

const _orderByOptions = [
  {"orderBy": "fileName", "name": "文件名排序"},
  {"orderBy": "size_asc", "name": "文件从小到大"},
  {"orderBy": "size_desc", "name": "文件从大到小"},
  {"orderBy": "modTime_asc", "name": "最早修改在前"},
  {"orderBy": "modTime_desc", "name": "最早修改在后"},
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
    orderBy = _orderByOptions[0]["orderBy"]!;
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
          pop();
        },
      ),
      title: Text(
        widget.name,
        style: theme.primaryTextTheme.titleMedium,
      ),
      actions: [buildAddMenu(theme), buildMoreMenu(theme)],
    );
  }

  PopupMenuButton<Text> buildMoreMenu(ThemeData theme) {
    return PopupMenuButton<Text>(
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
          for (var i = 0; i < _orderByOptions.length; i++)
            PopupMenuItem(
              enabled: _orderByOptions[i]["orderBy"]! != orderBy,
              child: Text(_orderByOptions[i]["name"]!),
              onTap: () => changeOrderBy(_orderByOptions[i]["orderBy"]!),
            )
        ];
      },
    );
  }

  PopupMenuButton<Text> buildAddMenu(ThemeData theme) {
    return PopupMenuButton<Text>(
      icon: Icon(
        Icons.add,
        color: theme.primaryIconTheme.color,
      ),
      itemBuilder: (context) {
        return [
          PopupMenuItem(
            child: Text("添加文件"),
            onTap: () => onAddFile(),
          ),
          PopupMenuItem(
            child: Text("创建文件夹"),
            onTap: () => onCreateFolder(),
          )
        ];
      },
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
      onLongPress: () {
        showItemOperationMenu(item);
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
      openNewPage(FileListPage(item.path, item.name));
    } else if (isImageFile(item.ext)) {
      openGallery(item);
    }
  }

  void openNewPage(Widget widget) {
    clearMessage();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => widget,
      ),
    );
  }

  void pop() {
    clearMessage();
    Navigator.of(context).pop();
  }

  void clearMessage() {
    ScaffoldMessenger.of(context).clearSnackBars();
  }

  void showMessage(String message) {
    clearMessage();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
    ));
  }

  onCreateFolder() async {
    Future.delayed(const Duration(milliseconds: 100), (() {
      showDialog(
          context: context,
          builder: ((context) => buildCreateFolderDialog(context)));
    }));
  }

  onAddFile() {}

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
    Result result = await api.postCreateFolder(widget.path, floderName);
    if (!result.success) {
      setState(() {
        showMessage(result.message!);
      });
      return;
    }
    setInitState();
    orderBy = "creTime_desc";
    fetchNext(widget.path);
  }

  void showItemOperationMenu(File item) {
    showDialog(
        context: context,
        builder: ((context) {
          return AlertDialog(
            title: Text("删除文件"),
            content: Text("确认删除 ${item.name} ？"),
            actions: [
              TextButton(
                  onPressed: (() {
                    pop();
                  }),
                  child: Text("取消")),
              TextButton(
                  onPressed: (() {
                    deleteFile(item.path);
                    pop();
                  }),
                  child: Text("确定"))
            ],
          );
        }));
  }

  Future<void> deleteFile(String path) async {
    print("delete $path");
    Result result = await api.postDeleteFile(path);
    if (!result.success) {
      setState(() {
        showMessage(result.message!);
      });
      return;
    }
    items.removeWhere((element) => element.path == path);
    setState(() {
      showMessage("删除成功");
    });
  }

  bool isImageFile(String? ext) {
    if (ext == null) {
      return false;
    }
    switch (ext) {
      case ".JPG":
      case ".JPEG":
      case ".PNG":
        return true;
      default:
        return false;
    }
  }

  void openGallery(File item) {
    List<File> images = [];
    int index = 0;
    for (var i = 0; i < items.length; i++) {
      var it = items[i];
      if (isImageFile(it.ext)) {
        images.add(it);
        if (it.path == item.path) {
          index = images.length - 1;
        }
      }
    }
    openNewPage(GalleryPhotoViewPage(images, index));
  }
}
