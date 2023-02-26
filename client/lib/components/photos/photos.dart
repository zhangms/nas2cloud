import 'package:flutter/material.dart';
import 'package:nas2cloud/components/viewer/gallery.dart';

import '../../api/api.dart';
import '../../dto/search_photo_response.dart';
import '../../pub/app_nav.dart';
import '../../pub/widgets.dart';
import '../../utils/file_helper.dart';
import '../files/file_widgets.dart';

class TimelinePhotoGridView extends StatefulWidget {
  @override
  State<TimelinePhotoGridView> createState() => _TimelinePhotoGridViewState();
}

class _TimelinePhotoGridViewState extends State<TimelinePhotoGridView> {
  static const int crossAxisCount = 6;

  String searchAfter = "";
  bool noMoreData = false;
  List<_GridItem> items = [];
  bool loading = false;

  @override
  void initState() {
    super.initState();
    loadPhoto();
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
    return GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 1,
          crossAxisSpacing: 1,
        ),
        itemBuilder: (context, index) => buildItem(context, index));
  }

  Widget? buildItem(BuildContext context, int index) {
    if (items.length <= index) {
      loadPhoto();
      return null;
    }
    var item = items[index];

    if (item.type == "groupTitle") {
      return Align(
        alignment: Alignment.bottomLeft,
        child: Text(item.group),
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
          return TextButton(
              onPressed: () => openGallery(index),
              child: buildThumb(ext, snapshot.data ?? Container()));
        });
  }

  Widget buildThumb(String ext, Widget widget) {
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
            items.add(_GridItem(type: "placeholder", group: preGroup));
          }
        }
        items.add(_GridItem(type: "groupTitle", group: group));
        for (int i = 0; i < crossAxisCount - 1; i++) {
          items.add(_GridItem(type: "placeholder", group: group));
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
}

class _GridItem {
  String type;
  String group;
  SearchPhotoResponseDataFiles? item;

  _GridItem({required this.type, required this.group, this.item});
}
