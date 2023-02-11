import 'dart:async';

import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:draggable_scrollbar/draggable_scrollbar.dart';
import 'package:flutter/material.dart';
import 'package:nas2cloud/components/files/file_item_trailing_star.dart';
import 'package:skeletons/skeletons.dart';

import '../../api/api.dart';
import '../../api/dto/file_walk_response/file.dart';
import '../../event/bus.dart';
import '../../pub/app_message.dart';
import '../../pub/app_nav.dart';
import '../../pub/widgets.dart';
import '../../utils/file_helper.dart';
import '../gallery/gallery.dart';
import '../gallery/pdf_viewer.dart';
import '../uploader/event_fileupload.dart';
import '../uploader/upload_entry.dart';
import '../uploader/upload_status.dart';
import 'file_data_controller.dart';
import 'file_event.dart';
import 'file_item_context_menu.dart';
import 'file_list_page.dart';
import 'file_widgets.dart';

class FileListView extends StatefulWidget {
  final String path;
  final int pageSize;
  final String orderByInitValue;
  final bool fileHome;

  FileListView(
      {required this.path,
      required this.pageSize,
      required this.orderByInitValue,
      required this.fileHome});

  @override
  State<FileListView> createState() => _FileListViewState();
}

class _FileListViewState extends State<FileListView> {
  final ScrollController scrollController = ScrollController();
  late final StreamSubscription<FileEvent> fileEventSubscription;
  late final StreamSubscription<EventFileUpload> eventFileUploadSubscription;
  late FileDataController fileDataController;

  late String orderBy;

  @override
  void initState() {
    super.initState();
    eventFileUploadSubscription =
        eventBus.on<EventFileUpload>().listen((event) {
      processFileUploadEvent(event.entry);
    });
    fileEventSubscription = eventBus.on<FileEvent>().listen((event) {
      processFileEvent(event);
    });
    initLoad(widget.orderByInitValue);
  }

  @override
  void dispose() {
    eventFileUploadSubscription.cancel();
    fileEventSubscription.cancel();
    super.dispose();
  }

  void initLoad(String sort) {
    orderBy = sort;
    fileDataController = FileDataController(
      path: widget.path,
      orderBy: sort,
      pageSize: widget.pageSize,
    );
    fileDataController.initLoad();
  }

  @override
  Widget build(BuildContext context) {
    if (fileDataController.initLoading) {
      return SkeletonListView();
    }
    if (fileDataController.total == 0) {
      return AppWidgets.pageEmptyView();
    }
    return DraggableScrollbar.semicircle(
      controller: scrollController,
      backgroundColor: Theme.of(context).colorScheme.background,
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
      trailing: buildItemTrailing(index, item),
      title: buildItemTitle(index, item),
      subtitle: Text("${item.modTime} ${item.size}"),
      onTap: () => tapItem(index, item),
    );
  }

  processFileUploadEvent(UploadEntry? entry) {
    if (entry != null &&
        entry.dest == widget.path &&
        "upload" == entry.channel &&
        UploadStatus.match(entry.status, UploadStatus.successed)) {
      initLoad("creTime_desc");
    }
  }

  void processFileEvent(FileEvent event) {
    if (widget.fileHome && event.type == FileEventType.toggleFavor) {
      var index = int.parse(event.source!);
      fileDataController.loadIndexPage(index);
      return;
    }
    if (event.currentPath != widget.path) {
      return;
    }
    switch (event.type) {
      case FileEventType.loaded:
        setState(() {});
        break;
      case FileEventType.createFolder:
        initLoad("creTime_desc");
        break;
      case FileEventType.orderBy:
        initLoad(event.source!);
        break;
      case FileEventType.delete:
        var index = int.parse(event.source!);
        fileDataController.loadIndexPage(index);
        break;
      case FileEventType.toggleFavor:
        var index = int.parse(event.source!);
        fileDataController.toggleFavor(index);
        setState(() {});
        break;
    }
  }

  Future<void> tapItem(int index, File item) async {
    if (item.type == "DIR") {
      AppNav.openPage(context, FileListPage(item.path, item.name));
    } else if (FileHelper.isPDF(item.ext)) {
      openPDFViewer(item);
    } else if (GalleryPhotoViewPage.isSupportFileExt(item.ext)) {
      openGallery(index, item);
    } else if (FileHelper.isMusic(item.ext)) {
      playMusic(index, item);
    } else if (mounted) {
      AppMessage.show(context, "不支持查看该类型的文件");
    }
  }

  void openGallery(int index, File item) {
    var items = fileDataController.getNearestItems(index);
    List<File> galleryItems = [];
    int galleryIndex = 0;
    for (var it in items) {
      if (GalleryPhotoViewPage.isSupportFileExt(it.ext)) {
        galleryItems.add(it);
        if (it.path == item.path) {
          galleryIndex = galleryItems.length - 1;
        }
      }
    }
    AppNav.openPage(context, GalleryPhotoViewPage(galleryItems, galleryIndex));
  }

  static final assetsAudioPlayer = AssetsAudioPlayer();

  Future<void> playMusic(int index, File item) async {
    var items = fileDataController.getNearestItems(index);
    List<Audio> playlist = [];
    int playIndex = 0;
    for (var it in items) {
      if (FileHelper.isMusic(it.ext)) {
        var audio = await buildNetworkAudio(it);
        playlist.add(audio);
        if (it.path == item.path) {
          playIndex = playlist.length - 1;
        }
      }
    }
    await assetsAudioPlayer.open(
      Playlist(audios: playlist, startIndex: playIndex),
      showNotification: true,
    );
  }

  Future<Audio> buildNetworkAudio(File it) async {
    var audioUrl = await Api().getStaticFileUrl(it.path);
    var httpHeaders = await Api().httpHeaders();
    MetasImage? metaImage;
    if (it.thumbnail != null) {
      var thumbUrl = await Api().getStaticFileUrl(it.thumbnail!);
      var signThumbUrl = await Api().signUrl(thumbUrl);
      metaImage = MetasImage.network(signThumbUrl);
    }
    var name = it.name;
    int index = name.lastIndexOf(".");
    if (index > 0) {
      name = name.substring(0, index);
    }
    return Audio.network(
      audioUrl,
      headers: httpHeaders,
      metas: Metas(
        title: name,
        image: metaImage,
      ),
    );
  }

  Future<void> openPDFViewer(File item) async {
    var url = await Api().getStaticFileUrl(item.path);
    var headers = await Api().httpHeaders();
    if (mounted) {
      AppNav.openPage(context, PDFViewer(url, headers));
    }
  }

  buildItemTrailing(int index, File item) {
    if (widget.fileHome) {
      if (item.favor ?? false) {
        return FileItemTailingStar(index, item);
      }
      return null;
    }
    return FileItemContextMenu(index, item, widget.path);
  }

  buildItemTitle(int index, File item) {
    if ((item.favor ?? false) && widget.fileHome) {
      return Text(
        item.favorName ?? item.name,
        overflow: TextOverflow.ellipsis,
      );
    }
    return Text(
      item.name,
      overflow: TextOverflow.ellipsis,
    );
  }
}
