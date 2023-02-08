import 'dart:async';

import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:draggable_scrollbar/draggable_scrollbar.dart';
import 'package:flutter/material.dart';
import 'package:nas2cloud/api/api.dart';
import 'package:nas2cloud/api/dto/file_walk_response/file.dart';
import 'package:nas2cloud/components/files/file_data_controller.dart';
import 'package:nas2cloud/components/files/file_event.dart';
import 'package:nas2cloud/components/files/file_menu_add.dart';
import 'package:nas2cloud/components/files/file_menu_more.dart';
import 'package:nas2cloud/components/gallery/gallery.dart';
import 'package:nas2cloud/components/gallery/pdf_viewer.dart';
import 'package:nas2cloud/components/uploader/upload_entry.dart';
import 'package:nas2cloud/components/uploader/upload_status.dart';
import 'package:nas2cloud/event/bus.dart';
import 'package:nas2cloud/event/event_fileupload.dart';
import 'package:nas2cloud/themes/app_nav.dart';
import 'package:nas2cloud/themes/widgets.dart';
import 'package:nas2cloud/utils/file_helper.dart';
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
  late final StreamSubscription<FileEvent> fileEventSubscription;
  late final StreamSubscription<EventFileUpload> eventFileUploadSubscription;
  late FileDataController fileDataController;

  late String orderBy;

  @override
  void initState() {
    super.initState();
    initLoad("modTime_desc");
    eventFileUploadSubscription =
        eventBus.on<EventFileUpload>().listen((event) {
      onUploadResultChange(event.entry);
    });
    fileEventSubscription = eventBus.on<FileEvent>().listen((event) {
      processFileEvent(event);
    });
  }

  onUploadResultChange(UploadEntry? entry) {
    if (entry != null &&
        entry.dest == widget.path &&
        "upload" == entry.channel &&
        UploadStatus.match(entry.status, UploadStatus.successed)) {
      setState(() {
        initLoad("creTime_desc");
      });
    }
  }

  void initLoad(String sort) {
    orderBy = sort;
    fileDataController = FileDataController(
      path: widget.path,
      orderBy: sort,
    );
    fileDataController.initLoad();
  }

  @override
  void dispose() {
    eventFileUploadSubscription.cancel();
    fileEventSubscription.cancel();
    super.dispose();
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
      actions: [FileAddMenu(widget.path), FileMoreMenu(widget.path, orderBy)],
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
      trailing: FileItemContextMenu(index, item, widget.path),
      title: Text(
        item.name,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text("${item.modTime} ${item.size}"),
      onTap: () => tapItem(index, item),
    );
  }

  void processFileEvent(FileEvent event) {
    if (event.currentPath != widget.path) {
      return;
    }
    switch (event.type) {
      case FileEventType.loaded:
        setState(() {});
        break;
      case FileEventType.createFloder:
        setState(() {
          initLoad("creTime_desc");
        });
        break;
      case FileEventType.orderBy:
        setState(() {
          initLoad(event.source!);
        });
        break;
      case FileEventType.delete:
        var index = int.parse(event.source!);
        fileDataController.loadIndexPage(index);
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
      AppWidgets.showMessage(context, "不支持查看该类型的文件");
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
}
