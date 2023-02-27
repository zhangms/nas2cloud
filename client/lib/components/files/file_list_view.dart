import 'dart:async';

import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:draggable_scrollbar/draggable_scrollbar.dart';
import 'package:flutter/material.dart';
import 'package:nas2cloud/components/uploader/auto_uploader.dart';
import 'package:skeletons/skeletons.dart';

import '../../api/api.dart';
import '../../dto/file_walk_response.dart';
import '../../dto/upload_entry.dart';
import '../../event/bus.dart';
import '../../pub/app_message.dart';
import '../../pub/app_nav.dart';
import '../../pub/widgets.dart';
import '../../utils/file_helper.dart';
import '../uploader/event_file_upload.dart';
import '../uploader/upload_status.dart';
import '../viewer/doc_viewer.dart';
import '../viewer/gallery.dart';
import '../viewer/pdf_viewer.dart';
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

  FileListView({
    required this.path,
    required this.pageSize,
    required this.orderByInitValue,
    required this.fileHome,
  });

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
    scrollController.dispose();
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
      return SkeletonListTile(hasSubtitle: true, padding: EdgeInsets.all(8));
    }
    bool favor = item.favor ?? false;
    String name = item.name;
    if (favor && widget.fileHome) {
      name = item.favorName ?? item.name;
    }
    var subtitle = "${item.modTime ?? ""} ${item.size ?? ""}".trim();
    return ListTile(
      leading: FileWidgets.getItemIcon(item),
      trailing: favor
          ? SizedBox(
              width: 50,
              child: Row(
                children: [
                  Icon(Icons.star, color: Colors.orange),
                  Icon(Icons.navigate_next)
                ],
              ),
            )
          : Icon(Icons.navigate_next),
      title: Text(name, overflow: TextOverflow.ellipsis),
      subtitle: subtitle.isEmpty ? null : Text(subtitle),
      onTap: () => tapItem(index, item),
      onLongPress: () => showContextMenu(index, item),
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

  Future<void> tapItem(int index, FileWalkResponseDataFiles item) async {
    if (item.type == "DIR") {
      AppNav.openPage(context, FileListPage(item.path, item.name));
    } else if (FileHelper.isPDF(item.ext)) {
      openPDFViewer(item);
    } else if (GalleryPhotoViewPage.isSupportFileExt(item.ext)) {
      openGallery(index, item);
    } else if (FileHelper.isMusic(item.ext)) {
      playMusic(index, item);
    } else if (FileHelper.isDoc(item.ext)) {
      openDoc(index, item);
    } else if (mounted) {
      AppMessage.show(context, "不支持查看该类型的文件");
    }
  }

  Future<void> openGallery(int index, FileWalkResponseDataFiles item) async {
    var items = fileDataController.getNearestItems(index);
    List<GalleryItem> galleryItems = [];
    int galleryIndex = 0;
    var headers = await Api().httpHeaders();
    for (var it in items) {
      if (GalleryPhotoViewPage.isSupportFileExt(it.ext)) {
        var url = await Api().getStaticFileUrl(it.path);
        galleryItems.add(GalleryItem(
          filepath: it.path,
          fileExt: it.ext,
          url: url,
          name: it.name,
          requestHeader: headers,
          size: it.size??"",
          modTime: it.modTime??"",
        ));
        if (it.path == item.path) {
          galleryIndex = galleryItems.length - 1;
        }
      }
    }
    if (mounted) {
      AppNav.openPage(
          context, GalleryPhotoViewPage(galleryItems, galleryIndex));
    }
  }

  static final assetsAudioPlayer = AssetsAudioPlayer();

  Future<void> playMusic(int index, FileWalkResponseDataFiles item) async {
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

  Future<Audio> buildNetworkAudio(FileWalkResponseDataFiles it) async {
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

  Future<void> openPDFViewer(FileWalkResponseDataFiles item) async {
    var url = await Api().getStaticFileUrl(item.path);
    var headers = await Api().httpHeaders();
    if (mounted) {
      AppNav.openPage(context, PDFViewer(url, headers));
    }
  }

  showContextMenu(int index, FileWalkResponseDataFiles item) async {
    if (widget.fileHome && !(item.favor ?? false)) {
      return;
    }
    bool isAutoUploaded = await AutoUploader().isFileAutoUploaded(item.path);
    var builder = FileItemContextMenuBuilder(
      currentPath: widget.path,
      index: index,
      item: item,
      isAutoUploaded: isAutoUploaded,
    );
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => builder.buildDialog(context),
      );
    }
  }

  Future<void> openDoc(int index, FileWalkResponseDataFiles item) async {
    var url = await Api().getStaticFileUrl(item.path);
    var headers = await Api().httpHeaders();
    if (mounted) {
      AppNav.openPage(context, DocViewer(url, headers));
    }
  }
}
