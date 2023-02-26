import 'dart:async';

import 'package:draggable_scrollbar/draggable_scrollbar.dart';
import 'package:flutter/material.dart';
import 'package:nas2cloud/components/viewer/gallery.dart';

import '../../api/api.dart';
import '../../dto/file_walk_response.dart';
import '../../dto/search_photo_response.dart';
import '../../event/bus.dart';
import '../../pub/app_nav.dart';
import '../../pub/widgets.dart';
import '../../utils/file_helper.dart';
import '../files/file_event.dart';
import '../files/file_item_context_menu.dart';
import '../files/file_widgets.dart';

class TimelinePhotoGridView extends StatefulWidget {
  @override
  State<TimelinePhotoGridView> createState() => _TimelinePhotoGridViewState();
}

class _TimelinePhotoGridViewState extends State<TimelinePhotoGridView> {
  static const int crossAxisCount = 8;

  final ScrollController scrollController = ScrollController();
  String searchAfter = "";
  bool noMoreData = false;
  List<_GridItem> items = [];
  bool loading = false;
  late final StreamSubscription<FileEvent> fileEventSubscription;

  @override
  void initState() {
    super.initState();
    fileEventSubscription = eventBus.on<FileEvent>().listen((event) {
      processFileEvent(event);
    });
    loadPhoto();
  }

  @override
  void dispose() {
    fileEventSubscription.cancel();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(context),
      body: buildBody(context),
    );
  }

  buildAppBar(BuildContext context) {
    return AppBar(
      leading: AppWidgets.appBarArrowBack(context),
      title: Text("照片"),
    );
  }

  buildBody(BuildContext context) {
    const int mainAxisExtent = 50;

    return DraggableScrollbar.semicircle(
      controller: scrollController,
      labelTextBuilder: (double offset) {
        int row = offset ~/ mainAxisExtent;
        int index = crossAxisCount * row;
        String group = "";
        if (index >= 0 && items.length > index) {
          group = items[index].group;
        }
        return Text(group);
      },
      backgroundColor: Theme.of(context).colorScheme.background,
      child: GridView.builder(
          controller: scrollController,
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisExtent: mainAxisExtent.toDouble(),
            mainAxisSpacing: 1,
            crossAxisSpacing: 1,
          ),
          itemBuilder: (context, index) => buildItem(context, index)),
    );
  }

  Widget? buildItem(BuildContext context, int index) {
    if (items.length <= index) {
      loadPhoto();
      return null;
    }
    if (items.isNotEmpty && items.length - index <= 10) {
      loadPhoto();
      return null;
    }
    var item = items[index];
    if (item.type == "groupTitle") {
      return Align(
        alignment: Alignment.bottomLeft,
        child: Text(item.text ?? ""),
      );
    }
    if (item.type == "placeholder") {
      return Container();
    }
    String ext = item.item?.ext ?? "";
    return FutureBuilder<Widget>(
        future: FileWidgets.buildImage(
            item.item?.thumbnail ?? "/assets/default_thumb.jpg"),
        builder: (context, snapshot) {
          return GestureDetector(
            child: buildThumb(ext, snapshot.data),
            onTap: () => openGallery(index),
            onLongPress: () => showContextMenu(index),
          );
        });
  }

  Widget buildThumb(String ext, Widget? widget) {
    if (widget == null) {
      return Container(
        color: Colors.black,
      );
    }
    if (FileHelper.isVideo(ext)) {
      return Stack(
        alignment: Alignment.center,
        children: [
          widget,
          Icon(
            Icons.play_circle,
            color: Colors.white,
          )
        ],
      );
    }
    return widget;
  }

  Future<void> loadPhoto() async {
    if (loading || noMoreData) {
      return;
    }
    try {
      print("begin--->$searchAfter");
      loading = true;
      SearchPhotoResponse response = await Api().searchPhoto(searchAfter);
      if (!response.success) {
        print(response.toJson());
        return;
      }
      if (response.data == null) {
        return;
      }
      SearchPhotoResponseData data = response.data!;
      var photoList = data.files ?? [];
      if (photoList.isEmpty) {
        noMoreData = true;
        return;
      }
      print("end--->${data.searchAfter}");
      onReceivePhotoList(photoList, data.searchAfter);
    } finally {
      loading = false;
    }
  }

  void onReceivePhotoList(
      List<SearchPhotoResponseDataFiles> photoList, String after) {
    for (int i = 0; i < photoList.length; i++) {
      var photo = photoList[i];
      String preGroup = getPreGroup();
      String group = getPhotoGroup(photo);
      if (group.isNotEmpty && group != preGroup) {
        int addCount = crossAxisCount - (items.length % crossAxisCount);
        if (addCount < crossAxisCount) {
          for (int i = 0; i < addCount; i++) {
            items
                .add(_GridItem(type: "placeholder", text: "", group: preGroup));
          }
        }
        var groups = group.split("-");
        if (groups.length == 2) {
          items.add(_GridItem(
              type: "groupTitle", group: group, text: "${groups[0]}年"));
          items.add(_GridItem(
              type: "groupTitle", group: group, text: "${groups[1]}月"));
          for (int i = 0; i < crossAxisCount - 2; i++) {
            items.add(_GridItem(type: "placeholder", group: group));
          }
        } else {
          items.add(_GridItem(type: "groupTitle", group: group));
          for (int i = 0; i < crossAxisCount - 1; i++) {
            items.add(_GridItem(type: "placeholder", group: group));
          }
        }
      }
      items.add(_GridItem(type: "item", group: group, item: photo));
    }

    setState(() {
      searchAfter = after;
    });
  }

  String getPreGroup() {
    if (items.isNotEmpty) {
      return items[items.length - 1].group;
    }
    return "";
  }

  String getPhotoGroup(SearchPhotoResponseDataFiles photo) {
    if (photo.modTime == null) {
      return "";
    }
    return photo.modTime!.substring(0, 7);
  }

  openGallery(int index) async {
    List<GalleryItem> galleryItems = [];
    int galleryIndex = 0;
    var headers = await Api().httpHeaders();
    for (int i = 0; i < items.length; i++) {
      var item = items[i];
      if (item.type != "item") {
        continue;
      }
      if (index == i) {
        galleryIndex = galleryItems.length;
      }
      var it = item.item!;
      var url = await Api().getStaticFileUrl(it.path);
      galleryItems.add(GalleryItem(
        filepath: it.path,
        url: url,
        name: it.name,
        requestHeader: headers,
        fileExt: it.ext,
      ));
    }
    if (mounted) {
      AppNav.openPage(
          context, GalleryPhotoViewPage(galleryItems, galleryIndex));
    }
  }

  showContextMenu(int index) {
    var item = items[index];
    if (item.item == null) {
      return;
    }
    var file = FileWalkResponseDataFiles.fromJson(item.item!.toJson());
    var builder = FileItemContextMenuBuilder(
      currentPath: "photoViews",
      index: index,
      item: file,
      isAutoUploaded: false,
    );
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => builder.buildDialog(context),
      );
    }
  }

  void processFileEvent(FileEvent event) {
    if (event.type == FileEventType.delete &&
        event.currentPath == "photoViews") {
      var index = int.parse(event.source ?? "-1");
      if (index > 0) {
        items.removeAt(index);
        setState(() {});
      }
    }
  }
}

class _GridItem {
  String type;
  String group;
  String? text;
  SearchPhotoResponseDataFiles? item;

  _GridItem({
    required this.type,
    required this.group,
    this.text,
    this.item,
  });
}
