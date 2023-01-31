import 'dart:async';

import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nas2cloud/api/api.dart';
import 'package:nas2cloud/api/dto/file_walk_request.dart';
import 'package:nas2cloud/api/dto/file_walk_response/file.dart';
import 'package:nas2cloud/api/dto/file_walk_response/file_walk_response.dart';
import 'package:nas2cloud/api/dto/result.dart';
import 'package:nas2cloud/components/downloader/downloader.dart';
import 'package:nas2cloud/components/files/file_widgets.dart';
import 'package:nas2cloud/components/gallery/gallery.dart';
import 'package:nas2cloud/components/uploader/file_uploder.dart';
import 'package:nas2cloud/components/uploader/pages/page_file_upload_task.dart';
import 'package:nas2cloud/components/uploader/upload_entry.dart';
import 'package:nas2cloud/components/uploader/upload_status.dart';
import 'package:nas2cloud/themes/widgets.dart';
import 'package:nas2cloud/utils/file_helper.dart';

class FileListPage extends StatefulWidget {
  final String path;
  final String name;

  FileListPage(this.path, this.name);

  @override
  State<FileListPage> createState() => _FileListPageState();
}

class _FileListPageState extends State<FileListPage> {
  static const _pageSize = 50;

  static const _orderByOptions = [
    {"orderBy": "fileName", "name": "文件名排序"},
    {"orderBy": "size_asc", "name": "文件从小到大"},
    {"orderBy": "size_desc", "name": "文件从大到小"},
    {"orderBy": "modTime_asc", "name": "最早修改在前"},
    {"orderBy": "modTime_desc", "name": "最早修改在后"},
    {"orderBy": "creTime_desc", "name": "最新添加"},
  ];

  static final _noDataResponse = FileWalkResponse.fromMap({
    "success": true,
  });

  late int total;
  late int currentStop;
  late int currentPage;
  late List<File> items;
  late String orderBy;
  bool fetchWhenBuild = true;

  @override
  void initState() {
    super.initState();
    FileUploader.addListener(onUploadResultChange);
    resetState();
  }

  @override
  void dispose() {
    FileUploader.removeListener(onUploadResultChange);
    super.dispose();
  }

  onUploadResultChange(UploadEntry entry) {
    if (UploadStatus.match(entry.status, UploadStatus.successed) &&
        entry.dest == widget.path) {
      resetFetch("creTime_desc");
    }
  }

  void resetState() {
    total = -1;
    currentStop = -1;
    currentPage = -1;
    items = [];
    orderBy = _orderByOptions[0]["orderBy"]!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(),
      body: FutureBuilder<FileWalkResponse>(
          future: fetchOnBuild(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              mergeFetched(snapshot.data!);
            }
            return SafeArea(child: buildBodyView(snapshot));
          }),
    );
  }

  Future<FileWalkResponse> fetchOnBuild() {
    if (fetchWhenBuild) {
      fetchWhenBuild = false;
      return fetch(widget.path, currentPage + 1, _pageSize, orderBy);
    }
    return Future.value(_noDataResponse);
  }

  Future<FileWalkResponse> fetch(
      String path, int pageNo, int pageSize, String orderBy) async {
    if (total >= 0 && items.length >= total) {
      return Future.value(_noDataResponse);
    }
    FileWalkRequest request = FileWalkRequest(
      path: path,
      pageNo: pageNo,
      pageSize: pageSize,
      orderBy: orderBy,
    );
    var resp = await Api.postFileWalk(request);
    if (resp.message == "RetryLaterAgain") {
      print("fetch RetryLaterAgain");
      return await Future<FileWalkResponse>.delayed(Duration(milliseconds: 100),
          () {
        return fetch(path, pageNo, pageSize, orderBy);
      });
    }
    return resp;
  }

  void mergeFetched(FileWalkResponse resp) {
    var data = resp.data;
    if (total < 0) {
      total = 0;
    }
    if (!resp.success) {
      return;
    }
    if (data == null) {
      return;
    }
    total = data.total;
    currentStop = data.currentStop;
    currentPage = data.currentPage;
    items.addAll(data.files ?? []);
  }

  Widget buildBodyView(AsyncSnapshot<FileWalkResponse> snapshot) {
    print("build body");
    if (total < 0) {
      return AppWidgets.getPageLoadingView();
    }
    if (total == 0) {
      return AppWidgets.getPageEmptyView();
    }
    return ListView.builder(
        itemCount: total,
        itemBuilder: ((context, index) {
          return buildItemView(index);
        }));
  }

  buildItemView(int index) {
    if (items.length - index < 20) {
      fetchNext();
    }
    if (items.length <= index) {
      return ListTile(
        leading: Icon(Icons.hourglass_empty),
      );
    }
    var item = items[index];
    return ListTile(
      leading: FileWidgets.getItemIcon(item),
      trailing: buildItemContextMenu(item),
      title: Text(item.name),
      subtitle: Text("${item.modTime}  ${item.size}"),
      onTap: () {
        onItemTap(item);
      },
    );
  }

  bool fetchingNext = false;

  Future<void> fetchNext() async {
    if (!fetchingNext && total > 0 && total > items.length) {
      fetchingNext = true;
      var nextPage = currentPage + 1;
      print("fetch next:  $nextPage");
      var resp = await fetch(widget.path, nextPage, _pageSize, orderBy);
      mergeFetched(resp);
      fetchingNext = false;
    }
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
            onTap: () => onTabCreateFolder(),
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
            onTap: (() => showCurrentPath()),
            child: Text("显示当前位置"),
          ),
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

  changeOrderBy(String order) {
    if (orderBy != order) {
      resetFetch(order);
    }
  }

  resetFetch(String order) {
    setState(() {
      resetState();
      orderBy = order;
      fetchWhenBuild = true;
    });
  }

  Future<void> createFolder(String floderName) async {
    if (floderName.trim().isEmpty) {
      return;
    }
    Result result = await Api.postCreateFolder(widget.path, floderName);
    if (!result.success) {
      showMessage(result.message!);
      return;
    }
    resetFetch("creTime_desc");
  }

  Future<void> deleteFile(String path) async {
    print("delete $path");
    Result result = await Api.postDeleteFile(path);
    if (!result.success) {
      showMessage(result.message!);
      return;
    }
    items.removeWhere((element) => element.path == path);
    total -= 1;
    showMessage("删除成功");
    setState(() {
      fetchWhenBuild = false;
    });
  }

  void download(File item) async {
    if (item.type == "DIR") {
      return;
    }
    var path = await Api.getStaticFileUrl(item.path);
    Downloader.platform.download(path);
    showMessage("已开始下载, 请从状态栏查看下载进度");
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
      FileUploader.platform.uploadPath(src: path!, dest: widget.path);
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

  onTabCreateFolder() async {
    Future.delayed(const Duration(milliseconds: 100), (() {
      showDialog(
          context: context,
          builder: ((context) => buildCreateFolderDialog(context)));
    }));
  }

  void onItemTap(File item) {
    if (item.type == "DIR") {
      openNewPage(FileListPage(item.path, item.name));
    } else if (GalleryPhotoViewPage.isSupportFileExt(item.ext)) {
      openGallery(item);
    } else if (FileHelper.isMusic(item.ext)) {
      playMusic(item);
    } else {
      showMessage("不支持查看该类型的文件");
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
    Future.delayed(Duration(milliseconds: 20), () {
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
          }));
    });
  }

  clearMessage() {
    ScaffoldMessenger.of(context).clearSnackBars();
  }

  void showMessage(String message) {
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
      FileUploader.platform.uploadStream(
        dest: widget.path,
        fileName: e.name,
        fileSize: e.size,
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
        if (FileHelper.isMusic(it.ext)) {
          var audioUrl = await Api.getStaticFileUrl(it.path);
          var httpHeaders = await Api.httpHeaders();
          var audioThumb =
              await Api.signUrl(await Api.getStaticFileUrl(it.thumbnail!));
          playlist.add(Audio.network(
            audioUrl,
            headers: httpHeaders,
            metas: Metas(
              title: name,
              image: () {
                if (it.thumbnail == null) {
                  return null;
                }
                return MetasImage.network(audioThumb);
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

  void showCurrentPath() {
    Future.delayed(Duration(milliseconds: 10), () {
      showDialog(
          context: context,
          builder: ((context) {
            return AlertDialog(
              title: Text("当前位置"),
              content: SelectableText(widget.path),
            );
          }));
    });
  }
}
