import 'package:draggable_scrollbar/draggable_scrollbar.dart';
import 'package:flutter/material.dart';
import 'package:nas2cloud/components/files/file_data_controller.dart';
import 'package:nas2cloud/components/files/file_menu_add.dart';
import 'package:nas2cloud/components/files/file_menu_more.dart';
import 'package:nas2cloud/components/uploader/file_uploder.dart';
import 'package:nas2cloud/components/uploader/upload_entry.dart';
import 'package:nas2cloud/components/uploader/upload_status.dart';
import 'package:nas2cloud/themes/widgets.dart';
import 'package:skeletons/skeletons.dart';

import 'file_menu_item_context.dart';
import 'file_widgets.dart';

class FileListPage extends StatefulWidget {
  final String path;
  final String name;

  FileListPage(this.path, this.name);

  @override
  State<FileListPage> createState() => _FileListPageState();
}

class _FileListPageState extends State<FileListPage> {
  final ScrollController scrollController = ScrollController();
  late final FileDataController fileDataController;

  @override
  void initState() {
    super.initState();
    fileDataController = FileDataController(widget.path, "fileName", () {
      print("callback");
      setState(() {});
    });
    fileDataController.initLoad();
    print("init load end");
    FileUploader.addListener(onUploadResultChange);
  }

  @override
  void dispose() {
    FileUploader.removeListener(onUploadResultChange);
    super.dispose();
  }

  onUploadResultChange(UploadEntry? entry) {
    if (entry != null &&
        entry.dest == widget.path &&
        "upload" == entry.channel &&
        UploadStatus.match(entry.status, UploadStatus.successed)) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(),
      body: SafeArea(child: buildBodyView()),
    );
  }

  buildAppBar() {
    return AppBar(
      leading: AppWidgets.appBarArrowBack(context),
      title: Text(widget.name),
      actions: [FileAddMenu(widget.path), FileMoreMenu(widget.path)],
    );
  }

  buildBodyView() {
    if (fileDataController.initLoading) {
      return AppWidgets.pageLoadingView();
    }
    if (fileDataController.total == 0) {
      return AppWidgets.pageEmptyView();
    }
    return DraggableScrollbar.semicircle(
      controller: scrollController,
      child: ListView.builder(
          controller: scrollController,
          itemExtent: 64,
          itemCount: fileDataController.total,
          itemBuilder: ((context, index) {
            return buildItemView(index);
          })),
    );
  }

  buildItemView(int index) {
    var item = fileDataController.get(index);
    if (item == null) {
      return SkeletonListTile(
        hasSubtitle: true,
        padding: EdgeInsets.all(8),
      );
    }
    return ListTile(
      leading: FileWidgets.getItemIcon(item),
      trailing: FileItemContextMenu(item),
      title: Text(
        item.name,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text("${item.modTime}  ${item.size}"),
      onTap: () {
        // onItemTap(item);
      },
    );
  }
}


  // Future<FileWalkResponse> fetchOnBuild() {
  //   if (fetchWhenBuild) {
  //     fetchWhenBuild = false;
  //     return fetch(widget.path, currentPage + 1, _pageSize, orderBy);
  //   }
  //   return Future.value(_noDataResponse);
  // }

  // Future<FileWalkResponse> fetch(
  //     String path, int pageNo, int pageSize, String orderBy) async {
  //   if (total >= 0 && items.length >= total) {
  //     return Future.value(_noDataResponse);
  //   }
  //   FileWalkRequest request = FileWalkRequest(
  //     path: path,
  //     pageNo: pageNo,
  //     pageSize: pageSize,
  //     orderBy: orderBy,
  //   );
  //   var resp = await Api().postFileWalk(request);
  //   if (resp.message == "RetryLaterAgain" && fetchRetryCount++ < 5) {
  //     print("fetch RetryLaterAgain");
  //     return await Future<FileWalkResponse>.delayed(Duration(milliseconds: 200),
  //         () {
  //       return fetch(path, pageNo, pageSize, orderBy);
  //     });
  //   }
  //   fetchRetryCount = 0;
  //   return resp;
  // }

  // void mergeFetched(FileWalkResponse resp) {
  //   var data = resp.data;
  //   if (total < 0) {
  //     total = 0;
  //   }
  //   if (!resp.success) {
  //     return;
  //   }
  //   if (data == null) {
  //     return;
  //   }
  //   total = data.total;
  //   currentStop = data.currentStop;
  //   currentPage = data.currentPage;
  //   items.addAll(data.files ?? []);
  // }

  // Widget buildBodyView(AsyncSnapshot<FileWalkResponse> snapshot) {
  //   if (total < 0) {
  //     return AppWidgets.pageLoadingView();
  //   }
  //   if (total == 0) {
  //     return AppWidgets.pageEmptyView();
  //   }
  //   return ListView.builder(
  //       itemCount: total,
  //       itemBuilder: ((context, index) {
  //         return buildItemView(index);
  //       }));
  // }

  // buildItemView(int index) {
  //   if (items.length - index < 20) {
  //     fetchNext();
  //   }
  //   if (items.length <= index) {
  //     return ListTile(
  //       leading: Icon(Icons.hourglass_empty),
  //     );
  //   }
  //   var item = items[index];
  //   return ListTile(
  //     leading: FileWidgets.getItemIcon(item),
  //     trailing: FileItemContextMenu(item),
  //     title: Text(item.name),
  //     subtitle: Text("${item.modTime}  ${item.size}"),
  //     onTap: () {
  //       onItemTap(item);
  //     },
  //   );
  // }

  // bool fetchingNext = false;

  // Future<void> fetchNext() async {
  //   if (!fetchingNext && total > 0 && total > items.length) {
  //     fetchingNext = true;
  //     var nextPage = currentPage + 1;
  //     print("fetch next:  $nextPage");
  //     var resp = await fetch(widget.path, nextPage, _pageSize, orderBy);
  //     mergeFetched(resp);
  //     fetchingNext = false;
  //   }
  // }

  // buildAppBar() {
  //   return AppBar(
  //     leading: AppWidgets.appBarArrowBack(context),
  //     title: Text(
  //       widget.name,
  //     ),
  //     actions: [FileAddMenu(widget.path), FileMoreMenu(widget.path)],
  //   );
  // }

  // resetFetch(String order) {
  //   setState(() {
  //     resetState();
  //     orderBy = order;
  //     fetchWhenBuild = true;
  //   });
  // }

  // void onItemTap(File item) {
  //   if (item.type == "DIR") {
  //     openNewPage(FileListPage(item.path, item.name));
  //   } else if (GalleryPhotoViewPage.isSupportFileExt(item.ext)) {
  //     openGallery(item);
  //   } else if (FileHelper.isMusic(item.ext)) {
  //     playMusic(item);
  //   } else {
  //     AppWidgets.showMessage(context, "不支持查看该类型的文件");
  //   }
  // }

  // void openGallery(File item) {
  //   List<File> images = [];
  //   int index = 0;
  //   for (var i = 0; i < items.length; i++) {
  //     var it = items[i];
  //     if (GalleryPhotoViewPage.isSupportFileExt(it.ext)) {
  //       images.add(it);
  //       if (it.path == item.path) {
  //         index = images.length - 1;
  //       }
  //     }
  //   }
  //   openNewPage(GalleryPhotoViewPage(images, index));
  // }

  // void openNewPage(Widget widget, {String? name}) {
  //   AppWidgets.clearMessage(context);
  //   AppNav.openPage(context, widget);
  // }

  // void pop() {
  //   AppWidgets.clearMessage(context);
  //   AppNav.pop(context);
  // }

  // static final assetsAudioPlayer = AssetsAudioPlayer();

  // Future<void> playMusic(File item) async {
  //   try {
  //     List<Audio> playlist = [];
  //     var playIndex = 0;
  //     bool playIndexFinded = false;
  //     for (var it in items) {
  //       var name = it.name;
  //       int index = name.lastIndexOf(".");
  //       if (index > 0) {
  //         name = name.substring(0, index);
  //       }
  //       if (FileHelper.isMusic(it.ext)) {
  //         var audioUrl = await Api().getStaticFileUrl(it.path);
  //         var httpHeaders = await Api().httpHeaders();
  //         var audioThumb =
  //             await Api().signUrl(await Api().getStaticFileUrl(it.thumbnail!));
  //         playlist.add(Audio.network(
  //           audioUrl,
  //           headers: httpHeaders,
  //           metas: Metas(
  //             title: name,
  //             image: () {
  //               if (it.thumbnail == null) {
  //                 return null;
  //               }
  //               return MetasImage.network(audioThumb);
  //             }(),
  //           ),
  //         ));
  //         if (it.path == item.path) {
  //           playIndexFinded = true;
  //         } else if (!playIndexFinded) {
  //           playIndex++;
  //         }
  //       }
  //     }
  //     if (!playIndexFinded) {
  //       playIndex = 0;
  //     }
  //     await assetsAudioPlayer.open(
  //       Playlist(audios: playlist, startIndex: playIndex),
  //       showNotification: true,
  //     );
  //   } catch (t) {
  //     print(t);
  //   }
  // }
