import 'package:flutter/material.dart';
import 'package:nas2cloud/pub/image_loader.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

import '../../api/api.dart';
import '../../api/dto/file_walk_response/file.dart';
import '../../pub/app_nav.dart';
import '../../pub/widgets.dart';
import '../../utils/file_helper.dart';
import 'pdf_viewer.dart';
import 'text_reader.dart';
import 'video_player.dart';

class GalleryPhotoViewPage extends StatefulWidget {
  static bool isSupportFileExt(String? ext) {
    if (FileHelper.isImage(ext) || FileHelper.isVideo(ext)) {
      return true;
    }
    if (FileHelper.isText(ext)) {
      return true;
    }
    return false;
  }

  final List<File> files;
  final int index;
  final PageController pageController;

  GalleryPhotoViewPage(this.files, this.index)
      : pageController = PageController(initialPage: index);

  @override
  State<GalleryPhotoViewPage> createState() => _GalleryPhotoViewPageState();
}

class _GalleryPhotoViewPageState extends State<GalleryPhotoViewPage> {
  var currentIndex = 0;

  late PhotoViewScaleStateController scaleStateController;
  late PhotoViewController controller;

  @override
  void initState() {
    super.initState();
    scaleStateController = PhotoViewScaleStateController();
    controller = PhotoViewController(initialScale: 1);
    currentIndex = widget.index;
  }

  @override
  void dispose() {
    scaleStateController.dispose();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: buildAppBar(),
        body: Container(
          constraints: BoxConstraints.expand(
            height: MediaQuery.of(context).size.height,
          ),
          child: FutureBuilder<List<_GalleryItem>>(
              future: getGalleryItems(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return AppWidgets.pageLoadingView();
                }
                galleryItems = snapshot.data!;
                return PhotoViewGallery.builder(
                  backgroundDecoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor),
                  scrollPhysics: const BouncingScrollPhysics(),
                  pageController: widget.pageController,
                  itemCount: galleryItems!.length,
                  scrollDirection: Axis.horizontal,
                  builder: buildView,
                  onPageChanged: (index) {
                    setState(() {
                      currentIndex = index;
                    });
                  },
                );
              }),
        ));
  }

  Future<List<_GalleryItem>> getGalleryItems() async {
    List<_GalleryItem> list = [];
    var headers = await Api().httpHeaders();
    for (var file in widget.files) {
      var url = await Api().getStaticFileUrl(file.path);
      list.add(_GalleryItem(
        filepath: file.path,
        fileExt: file.ext,
        url: url,
        name: file.name,
        requestHeader: headers,
      ));
    }
    return list;
  }

  List<_GalleryItem>? galleryItems;

  PhotoViewGalleryPageOptions buildView(BuildContext context, int idx) {
    var item = galleryItems?[idx];
    if (item == null) {
      return PhotoViewGalleryPageOptions.customChild(
          child: AppWidgets.pageErrorView("NotFound"));
    }

    // CachedNetworkImage(
    //   imageUrl: "http://via.placeholder.com/350x150",
    //   progressIndicatorBuilder: (context, url, downloadProgress) =>
    //       CircularProgressIndicator(value: downloadProgress.progress),
    //   errorWidget: (context, url, error) => Icon(Icons.error),
    // );

    // NetworkImage(item.url, headers: item.requestHeader)
    if (FileHelper.isImage(item.fileExt)) {
      return PhotoViewGalleryPageOptions(
          imageProvider: ImageLoader.cacheNetworkImageProvider(
              item.url, item.requestHeader),
          initialScale: PhotoViewComputedScale.contained,
          minScale: PhotoViewComputedScale.contained * 0.5,
          maxScale: PhotoViewComputedScale.covered * 4.1,
          heroAttributes: PhotoViewHeroAttributes(tag: item.filepath),
          controller: controller,
          scaleStateController: scaleStateController);
    } else if (FileHelper.isVideo(item.fileExt)) {
      return PhotoViewGalleryPageOptions.customChild(
          child: VideoPlayerWapper(item.url, item.requestHeader));
    } else if (FileHelper.isPDF(item.fileExt)) {
      return PhotoViewGalleryPageOptions.customChild(
          child: PDFViewer(item.url, item.requestHeader));
    } else if (FileHelper.isText(item.fileExt)) {
      return PhotoViewGalleryPageOptions.customChild(
          child: TextReader(item.filepath, item.requestHeader));
    } else {
      return PhotoViewGalleryPageOptions.customChild(
          child: AppWidgets.pageErrorView("UNSUPPORT"));
    }
  }

  buildAppBar() {
    var index = currentIndex + 1;
    var item = widget.files[currentIndex];
    return AppBar(
      leading: IconButton(
        icon: Icon(Icons.arrow_back),
        onPressed: () => AppNav.pop(context),
      ),
      title: Text("($index/${widget.files.length})${item.name}"),
    );
  }
}

class _GalleryItem {
  String filepath;
  String? fileExt;
  String url;
  String name;
  Map<String, String> requestHeader;

  _GalleryItem(
      {required this.filepath,
      this.fileExt,
      required this.url,
      required this.name,
      required this.requestHeader});
}
