import 'dart:async';

import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nas2cloud/api/api.dart';
import 'package:nas2cloud/api/dto/file_upload_record.dart';
import 'package:nas2cloud/api/dto/file_upload_status_enum.dart';
import 'package:nas2cloud/api/dto/file_walk_request.dart';
import 'package:nas2cloud/api/dto/file_walk_response/file.dart';
import 'package:nas2cloud/api/dto/result.dart';
import 'package:nas2cloud/components/downloader.dart';
import 'package:nas2cloud/components/uploader/file_uploder.dart';
import 'package:nas2cloud/pages/app/file_ext.dart';
import 'package:nas2cloud/pages/app/file_upload_task.dart';
import 'package:nas2cloud/pages/app/gallery.dart';

const _orderByOptions = [
  {"orderBy": "fileName", "name": "文件名排序"},
  {"orderBy": "size_asc", "name": "文件从小到大"},
  {"orderBy": "size_desc", "name": "文件从大到小"},
  {"orderBy": "modTime_asc", "name": "最早修改在前"},
  {"orderBy": "modTime_desc", "name": "最早修改在后"},
  {"orderBy": "creTime_desc", "name": "最新添加"},
];

const _pageSize = 50;

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
    FileUploader.get().addListener(onUploadChange);
    _setInitState();
    fetchNext(widget.path);
    // Timer(Duration(milliseconds: 100), () => fetchNext(widget.path));
  }

  void _setInitState() {
    total = -1;
    currentStop = -1;
    currentPage = -1;
    fetching = false;
    items = [];
    orderBy = _orderByOptions[0]["orderBy"]!;
  }

  @override
  void dispose() {
    FileUploader.get().removeListener(onUploadChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(),
      body: SafeArea(child: buildBodyView()),
    );
  }

  PopupMenuButton<Text> buildAddMenu() {
    return PopupMenuButton<Text>(
      icon: Icon(
        Icons.add,
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
          ),
          PopupMenuDivider(),
          PopupMenuItem(
            child: Text("文件上传任务列表"),
            onTap: () => openUploadTaskPage(),
          ),
        ];
      },
    );
  }

  buildAppBar() {
    return AppBar(
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back,
        ),
        onPressed: () {
          pop();
        },
      ),
      title: Text(
        widget.name,
      ),
      actions: [buildAddMenu(), buildMoreMenu()],
    );
  }

  Widget buildBodyView() {
    if (total <= 0) {
      return Center(child: total < 0 ? Text("Loading...") : Text("Empty"));
    }
    return ListView.builder(
        itemCount: total >= 0 ? total : 0,
        itemBuilder: ((context, index) {
          return buildItemView(index);
        }));
  }

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

  buildItemContextMenu(File item) {
    return PopupMenuButton<Text>(
      icon: Icon(
        Icons.more_horiz_rounded,
      ),
      itemBuilder: (context) {
        return [
          if (item.type != "DIR")
            PopupMenuItem(
              child: ListTile(
                leading: Icon(Icons.download),
                title: Text("下载"),
              ),
              onTap: () => download(item),
            ),
          PopupMenuItem(
            child: ListTile(
              leading: Icon(Icons.delete),
              title: Text("删除"),
            ),
            onTap: () => showItemDeleteConfirm(item),
          ),
        ];
      },
    );
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
      leading: FileExt.getItemIcon(item),
      trailing: buildItemContextMenu(item),
      title: Text(item.name),
      subtitle: Text("${item.modTime}  ${item.size}"),
      onTap: () {
        onItemTap(item);
      },
    );
  }

  PopupMenuButton<Text> buildMoreMenu() {
    return PopupMenuButton<Text>(
      icon: Icon(
        Icons.more_horiz,
      ),
      itemBuilder: (context) {
        return [
          for (var i = 0; i < _orderByOptions.length; i++)
            PopupMenuItem(
              enabled: _orderByOptions[i]["orderBy"]! != orderBy,
              child: Text(_orderByOptions[i]["name"]!),
              onTap: () => changeOrderBy(_orderByOptions[i]["orderBy"]!),
            ),
          PopupMenuDivider(),
          PopupMenuItem(
            onTap: (() {
              popAll();
            }),
            child: Text("回到首页"),
          ),
        ];
      },
    );
  }

  Future<void> popAll() async {
    var nav = Navigator.of(context);
    nav.pushNamedAndRemoveUntil("/home", ModalRoute.withName('/'));
  }

  changeOrderBy(String order) {
    if (orderBy == order) {
      return;
    }
    _setInitState();
    setState(() {
      orderBy = order;
    });
    fetchNext(widget.path);
  }

  void clearMessage() {
    ScaffoldMessenger.of(context).clearSnackBars();
  }

  Future<void> createFolder(String floderName) async {
    if (floderName.trim().isEmpty) {
      return;
    }
    Result result = await Api.postCreateFolder(widget.path, floderName);
    if (!result.success) {
      setState(() {
        showMessage(result.message!);
      });
      return;
    }
    _setInitState();
    orderBy = "creTime_desc";
    fetchNext(widget.path);
  }

  Future<void> deleteFile(String path) async {
    print("delete $path");
    Result result = await Api.postDeleteFile(path);
    if (!result.success) {
      setState(() {
        showMessage(result.message!);
      });
      return;
    }
    items.removeWhere((element) => element.path == path);
    setState(() {
      total -= 1;
      showMessage("删除成功");
    });
  }

  void download(File item) {
    if (item.type == "DIR") {
      return;
    }
    Downloader.get().download(Api.getStaticFileUrl(item.path));
    showMessage("已开始下载, 请从状态栏查看下载进度");
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
      var resp = await Api.postFileWalk(request);
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

  Future<void> nativeUpload() async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result == null) {
      return;
    }
    for (var i = 0; i < result.paths.length; i++) {
      var path = result.paths[i];
      print(path);
      FileUploader.get().uploadPath(src: path!, dest: widget.path);
    }
    openNewPage(FileUploadTaskPage());
  }

  onAddFile() async {
    Future.delayed(const Duration(milliseconds: 100), (() {
      if (kIsWeb) {
        webUpload();
      } else {
        nativeUpload();
      }
    }));
  }

  onCreateFolder() async {
    Future.delayed(const Duration(milliseconds: 100), (() {
      showDialog(
          context: context,
          builder: ((context) => buildCreateFolderDialog(context)));
    }));
  }

  void onItemTap(File item) {
    if (item.type == "DIR") {
      openNewPage(FileListPage(item.path, item.name), name: item.path);
    } else if (GalleryPhotoViewPage.isSupportFileExt(item.ext)) {
      openGallery(item);
    } else if (FileExt.isMusic(item.ext)) {
      playMusic(item);
    } else {
      showMessage("不支持查看该类型的文件");
    }
  }

  void onUploadChange(FileUploadRecord record) {
    if (record.dest == widget.path) {
      if (record.status == FileUploadStatus.success.name) {
        _setInitState();
        orderBy = "creTime_desc";
        fetchNext(widget.path);
      }
    }
  }

  void openGallery(File item) {
    List<File> images = [];
    int index = 0;
    for (var i = 0; i < items.length; i++) {
      var it = items[i];
      if (GalleryPhotoViewPage.isSupportFileExt(it.ext)) {
        images.add(it);
        if (it.path == item.path) {
          index = images.length - 1;
        }
      }
    }
    openNewPage(GalleryPhotoViewPage(images, index));
  }

  void openNewPage(Widget widget, {String? name}) {
    clearMessage();
    Navigator.of(context).push(
      MaterialPageRoute(
        settings: RouteSettings(name: name),
        builder: (context) => widget,
      ),
    );
  }

  openUploadTaskPage() {
    Future.delayed(const Duration(milliseconds: 100), (() {
      openNewPage(FileUploadTaskPage());
    }));
  }

  void pop() {
    clearMessage();
    Navigator.of(context).pop();
  }

  void showItemDeleteConfirm(File item) {
    Future.delayed(
        Duration(milliseconds: 20),
        () => {
              showDialog(
                  context: context,
                  builder: ((context) {
                    return AlertDialog(
                      title: Text("删除文件"),
                      content: Text("确认删除 ${item.name} ?"),
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
                  }))
            });
  }

  void showMessage(String message) {
    clearMessage();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
    ));
  }

  Future<void> webUpload() async {
    FilePickerResult? result = await FilePicker.platform
        .pickFiles(allowMultiple: true, withData: false, withReadStream: true);
    if (result == null) {
      return;
    }
    for (var i = 0; i < result.files.length; i++) {
      var e = result.files[i];
      print(e);
      if (e.readStream == null) {
        continue;
      }
      FileUploader.get().uploadStream(
        dest: widget.path,
        fileName: e.name,
        size: e.size,
        stream: e.readStream!,
      );
    }
    openNewPage(FileUploadTaskPage());
  }

  static final assetsAudioPlayer = AssetsAudioPlayer();

  Future<void> playMusic(File item) async {
    try {
      List<Audio> playlist = [];
      var playIndex = 0;
      bool playIndexFinded = false;
      for (var it in items) {
        var name = it.name;
        int index = name.lastIndexOf(".");
        if (index > 0) {
          name = name.substring(0, index);
        }
        if (FileExt.isMusic(it.ext)) {
          playlist.add(Audio.network(
            Api.getStaticFileUrl(it.path),
            headers: Api.httpHeaders(),
            metas: Metas(
              title: name,
              image: () {
                if (it.thumbnail == null) {
                  return null;
                }
                return MetasImage.network(
                    Api.signUrl(Api.getStaticFileUrl(it.thumbnail!)));
              }(),
            ),
          ));
          if (it.path == item.path) {
            playIndexFinded = true;
          } else if (!playIndexFinded) {
            playIndex++;
          }
        }
      }
      if (!playIndexFinded) {
        playIndex = 0;
      }
      await assetsAudioPlayer.open(
        Playlist(audios: playlist, startIndex: playIndex),
        showNotification: true,
      );
    } catch (t) {
      print(t);
    }
  }
}
