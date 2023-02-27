import 'dart:async';

import 'package:draggable_scrollbar/draggable_scrollbar.dart';
import 'package:flutter/material.dart';
import 'package:nas2cloud/api/api.dart';
import 'package:nas2cloud/dto/search_photo_count_response.dart';

import '../../dto/file_walk_response.dart';
import '../../dto/search_photo_response.dart';
import '../../event/bus.dart';
import '../../pub/app_nav.dart';
import '../../pub/widgets.dart';
import '../../utils/file_helper.dart';
import '../files/file_event.dart';
import '../files/file_item_context_menu.dart';
import '../files/file_widgets.dart';
import '../viewer/gallery.dart';

class TimelinePhotoGridView extends StatefulWidget {
  @override
  State<TimelinePhotoGridView> createState() => _TimelinePhotoGridViewState();
}

class _TimelinePhotoGridViewState extends State<TimelinePhotoGridView> {
  static const int crossAxisCount = 8;

  final ScrollController scrollController = ScrollController();
  late final StreamSubscription<FileEvent> fileEventSubscription;
  bool loading = false;
  int totalCount = 0;
  List<_GridGroup> groups = [];

  @override
  void initState() {
    super.initState();
    fileEventSubscription = eventBus.on<FileEvent>().listen((event) {
      processFileEvent(event);
    });
    loadPhotoCount();
    // loadPhoto();
    // loadPhotoCount();
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
        int row = offset ~/ (mainAxisExtent + 1);
        int index = crossAxisCount * row;
        return Text(getIndexGroupName(index));
      },
      backgroundColor: Theme.of(context).colorScheme.background,
      child: GridView.builder(
          controller: scrollController,
          itemCount: totalCount,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisExtent: mainAxisExtent.toDouble(),
            mainAxisSpacing: 1,
            crossAxisSpacing: 1,
          ),
          itemBuilder: (context, index) => buildItem(context, index)),
    );
  }

  void processFileEvent(FileEvent event) {
    if (event.type == FileEventType.delete &&
        event.currentPath == "photoViews") {
      var index = int.parse(event.source ?? "-1");
      if (index > 0) {
        _GridGroup? group = getIndexGroup(index);
        if (group != null) {
          group.removeIndex(index);
          setState(() {});
        }
      }
    }
  }

  Widget? buildItem(BuildContext context, int index) {
    _GridGroup? group = getIndexGroup(index);
    if (group == null) {
      return null;
    }
    _GridItem? item = group.getItem(index);
    if (item == null) {
      tryLoadGroupData(group);
      return Container(
        color: Theme.of(context).colorScheme.tertiary,
      );
    }
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

  _GridGroup? getIndexGroup(int index) {
    for (var value in groups) {
      if (index >= value.startIndex && index < value.endIndex) {
        return value;
      }
    }
    print("totalCount: $totalCount, index:$index ");
    if (groups.isNotEmpty) {
      return groups[groups.length - 1];
    }
    return null;
  }

  String getIndexGroupName(int index) {
    return getIndexGroup(index)?.group ?? "";
  }

  Future<void> loadPhotoCount() async {
    SearchPhotoCountResponse response = await Api().searchPhotoCount();
    if (!response.success) {
      return;
    }
    var counter = response.data ?? [];
    List<_GridGroup> groupData = [];
    int total = 0;
    for (var value in counter) {
      if (value.value <= 0) {
        continue;
      }
      var preEnd = total;
      var tailingCount = crossAxisCount - (value.value % crossAxisCount);
      total += (value.value + crossAxisCount + tailingCount);
      groupData.add(_GridGroup(
        group: value.key,
        startIndex: preEnd,
        endIndex: total,
        leadingCount: crossAxisCount,
        tailingCount: tailingCount,
        itemCount: value.value,
      ));
    }
    setState(() {
      totalCount = total;
      groups = groupData;
    });
  }

  buildThumb(String ext, Widget? widget) {
    if (widget == null) {
      return Container(
        color: Theme.of(context).colorScheme.tertiary,
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

  openGallery(int index) async {
    var currentGroup = getIndexGroup(index);
    if (currentGroup == null) {
      return;
    }
    var current = currentGroup.getItem(index);
    if (current == null || current.item == null) {
      return;
    }
    List<GalleryItem> galleryItems = [];
    int galleryIndex = 0;
    var headers = await Api().httpHeaders();
    for (var group in groups) {
      for (var item in group.items) {
        var it = item.item!;
        var url = await Api().getStaticFileUrl(it.path);
        galleryItems.add(GalleryItem(
          filepath: it.path,
          url: url,
          name: it.name,
          requestHeader: headers,
          fileExt: it.ext,
        ));
        if (current == item) {
          galleryIndex = galleryItems.length - 1;
        }
      }
    }
    if (mounted) {
      AppNav.openPage(
          context, GalleryPhotoViewPage(galleryItems, galleryIndex));
    }
  }

  showContextMenu(int index) {
    var group = getIndexGroup(index);
    if (group == null) {
      return;
    }
    var item = group.getItem(index);
    if (item == null || item.item == null) {
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

  Future<void> tryLoadGroupData(_GridGroup group) async {
    if (group.loading || group.noMoreData) {
      return;
    }
    try {
      group.loading = true;
      print("begin--->${group.group} : ${group.searchAfter}");
      var resp = await Api().searchPhoto(group.searchAfter);
      if (!resp.success) {
        print(resp.toJson());
        return;
      }
      if (resp.data == null) {
        return;
      }
      var data = resp.data!;
      var photoList = data.files ?? [];
      if (photoList.isEmpty) {
        group.noMoreData = true;
        return;
      }
      group.searchAfter = data.searchAfter;
      group.receive(photoList);
      setState(() {});
    } finally {
      group.loading = false;
      print("end--->${group.group} : ${group.searchAfter}");
    }
  }
}

class _GridGroup {
  final String group;
  final int startIndex;
  final int endIndex;
  final int leadingCount;
  final List<_GridItem> items = [];
  int itemCount;
  int tailingCount;
  bool loading = false;
  bool noMoreData = false;
  String searchAfter = "";

  _GridGroup({
    required this.group,
    required this.startIndex,
    required this.endIndex,
    required this.leadingCount,
    required this.tailingCount,
    required this.itemCount,
  });

  _GridItem? getItem(int index) {
    if (index < startIndex || index >= endIndex) {
      throw "error index range : $index";
    }
    var di = index - startIndex;
    if (di < leadingCount) {
      if (di == 0) {
        return _GridItem(type: "groupTitle", text: "${group.split("-")[0]}年");
      }
      if (di == 1) {
        return _GridItem(type: "groupTitle", text: "${group.split("-")[1]}月");
      }
      return _GridItem(type: "placeholder");
    }
    di -= leadingCount;
    if (di < itemCount) {
      if (items.length > di) {
        return items[di];
      }
      print("need load--->$di, $group");
      return null;
    }
    return _GridItem(type: "placeholder");
  }

  void receive(List<SearchPhotoResponseDataFiles> photoList) {
    print("group $group receive data count:${photoList.length}");
    for (var value in photoList) {
      if (items.length < itemCount) {
        items.add(_GridItem(type: "item", item: value));
      }
    }
  }

  void removeIndex(int index) {
    var di = index - startIndex;
    di -= leadingCount;
    if (di < itemCount && di < items.length) {
      items.removeAt(di);
      itemCount--;
      tailingCount++;
    }
  }
}

class _GridItem {
  String type;
  String? text;
  SearchPhotoResponseDataFiles? item;

  _GridItem({
    required this.type,
    this.text,
    this.item,
  });
}

// class _TimelinePhotoGridViewState extends State<TimelinePhotoGridView> {
//   static const int crossAxisCount = 8;
//
//   final ScrollController scrollController = ScrollController();
//   String searchAfter = "";
//   bool noMoreData = false;
//   // List<_GridItem> items = [];
//   bool loading = false;
//   late final StreamSubscription<FileEvent> fileEventSubscription;
//
//   @override
//   void initState() {
//     super.initState();
//     fileEventSubscription = eventBus.on<FileEvent>().listen((event) {
//       processFileEvent(event);
//     });
//     // loadPhoto();
//     // loadPhotoCount();
//   }
//
//   @override
//   void dispose() {
//     fileEventSubscription.cancel();
//     scrollController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: buildAppBar(context),
//       body: buildBody(context),
//     );
//   }
//
//   buildAppBar(BuildContext context) {
//     return AppBar(
//       leading: AppWidgets.appBarArrowBack(context),
//       title: Text("照片"),
//     );
//   }
//
//   buildBody(BuildContext context) {
//     const int mainAxisExtent = 50;
//
//     return DraggableScrollbar.semicircle(
//       controller: scrollController,
//       labelTextBuilder: (double offset) {
//         int row = offset ~/ mainAxisExtent;
//         int index = crossAxisCount * row;
//         return Text(getIndexGroup(index));
//       },
//       backgroundColor: Theme.of(context).colorScheme.background,
//       child: GridView.builder(
//           controller: scrollController,
//           itemCount: items.length,
//           gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//             crossAxisCount: crossAxisCount,
//             mainAxisExtent: mainAxisExtent.toDouble(),
//             mainAxisSpacing: 1,
//             crossAxisSpacing: 1,
//           ),
//           itemBuilder: (context, index) => buildItem(context, index)),
//     );
//   }
//
//   Widget? buildItem(BuildContext context, int index) {
//     if (items.length <= index) {
//       loadPhoto();
//       return null;
//     }
//     if (items.isNotEmpty && items.length - index <= 10) {
//       loadPhoto();
//       return null;
//     }
//     var item = items[index];
//     if (item.type == "groupTitle") {
//       return Align(
//         alignment: Alignment.bottomLeft,
//         child: Text(item.text ?? ""),
//       );
//     }
//     if (item.type == "placeholder") {
//       return Container();
//     }
//     String ext = item.item?.ext ?? "";
//     return FutureBuilder<Widget>(
//         future: FileWidgets.buildImage(
//             item.item?.thumbnail ?? "/assets/default_thumb.jpg"),
//         builder: (context, snapshot) {
//           return GestureDetector(
//             child: buildThumb(ext, snapshot.data),
//             onTap: () => openGallery(index),
//             onLongPress: () => showContextMenu(index),
//           );
//         });
//   }
//
//   Widget buildThumb(String ext, Widget? widget) {
//     if (widget == null) {
//       return Container(
//         color: Colors.black,
//       );
//     }
//     if (FileHelper.isVideo(ext)) {
//       return Stack(
//         alignment: Alignment.center,
//         children: [
//           widget,
//           Icon(
//             Icons.play_circle,
//             color: Colors.white,
//           )
//         ],
//       );
//     }
//     return widget;
//   }
//
//   Future<void> loadPhoto() async {
//     if (loading || noMoreData) {
//       return;
//     }
//     try {
//       print("begin--->$searchAfter");
//       loading = true;
//       SearchPhotoResponse response = await Api().searchPhoto(searchAfter);
//       if (!response.success) {
//         print(response.toJson());
//         return;
//       }
//       if (response.data == null) {
//         return;
//       }
//       SearchPhotoResponseData data = response.data!;
//       var photoList = data.files ?? [];
//       if (photoList.isEmpty) {
//         noMoreData = true;
//         return;
//       }
//       print("end--->${data.searchAfter}");
//       onReceivePhotoList(photoList, data.searchAfter);
//     } finally {
//       loading = false;
//     }
//   }
//
//   void onReceivePhotoList(
//       List<SearchPhotoResponseDataFiles> photoList, String after) {
//     for (int i = 0; i < photoList.length; i++) {
//       var photo = photoList[i];
//       String preGroup = getPreGroup();
//       String group = getPhotoGroup(photo);
//       if (group.isNotEmpty && group != preGroup) {
//         int addCount = crossAxisCount - (items.length % crossAxisCount);
//         if (addCount < crossAxisCount) {
//           for (int i = 0; i < addCount; i++) {
//             items
//                 .add(_GridItem(type: "placeholder", text: "", group: preGroup));
//           }
//         }
//         var groups = group.split("-");
//         if (groups.length == 2) {
//           items.add(_GridItem(
//               type: "groupTitle", group: group, text: "${groups[0]}年"));
//           items.add(_GridItem(
//               type: "groupTitle", group: group, text: "${groups[1]}月"));
//           for (int i = 0; i < crossAxisCount - 2; i++) {
//             items.add(_GridItem(type: "placeholder", group: group));
//           }
//         } else {
//           items.add(_GridItem(type: "groupTitle", group: group));
//           for (int i = 0; i < crossAxisCount - 1; i++) {
//             items.add(_GridItem(type: "placeholder", group: group));
//           }
//         }
//       }
//       items.add(_GridItem(type: "item", group: group, item: photo));
//     }
//
//     setState(() {
//       searchAfter = after;
//     });
//   }
//
//   String getPreGroup() {
//     if (items.isNotEmpty) {
//       return items[items.length - 1].group;
//     }
//     return "";
//   }
//
//   String getPhotoGroup(SearchPhotoResponseDataFiles photo) {
//     if (photo.modTime == null) {
//       return "";
//     }
//     return photo.modTime!.substring(0, 7);
//   }
//
//   openGallery(int index) async {
//     List<GalleryItem> galleryItems = [];
//     int galleryIndex = 0;
//     var headers = await Api().httpHeaders();
//     for (int i = 0; i < items.length; i++) {
//       var item = items[i];
//       if (item.type != "item") {
//         continue;
//       }
//       if (index == i) {
//         galleryIndex = galleryItems.length;
//       }
//       var it = item.item!;
//       var url = await Api().getStaticFileUrl(it.path);
//       galleryItems.add(GalleryItem(
//         filepath: it.path,
//         url: url,
//         name: it.name,
//         requestHeader: headers,
//         fileExt: it.ext,
//       ));
//     }
//     if (mounted) {
//       AppNav.openPage(
//           context, GalleryPhotoViewPage(galleryItems, galleryIndex));
//     }
//   }
//
//   showContextMenu(int index) {
//     var item = items[index];
//     if (item.item == null) {
//       return;
//     }
//     var file = FileWalkResponseDataFiles.fromJson(item.item!.toJson());
//     var builder = FileItemContextMenuBuilder(
//       currentPath: "photoViews",
//       index: index,
//       item: file,
//       isAutoUploaded: false,
//     );
//     if (mounted) {
//       showDialog(
//         context: context,
//         builder: (context) => builder.buildDialog(context),
//       );
//     }
//   }
//
//   void processFileEvent(FileEvent event) {
//     if (event.type == FileEventType.delete &&
//         event.currentPath == "photoViews") {
//       var index = int.parse(event.source ?? "-1");
//       if (index > 0) {
//         items.removeAt(index);
//         setState(() {});
//       }
//     }
//   }
//
//   String getIndexGroup(int index) {
//     return "";
//   }
// }
