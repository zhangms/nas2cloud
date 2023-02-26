import 'package:flutter/material.dart';
import 'package:nas2cloud/pub/image_loader.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

import '../../pub/app_message.dart';
import '../../pub/app_nav.dart';
import '../../pub/widgets.dart';
import '../../utils/file_helper.dart';
import '../downloader/downloader.dart';
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

  final List<GalleryItem> items;
  final int index;
  final PageController pageController;

  GalleryPhotoViewPage(this.items, this.index)
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
            child: PhotoViewGallery.builder(
              backgroundDecoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor),
              scrollPhysics: const BouncingScrollPhysics(),
              pageController: widget.pageController,
              itemCount: widget.items.length,
              scrollDirection: Axis.horizontal,
              builder: buildView,
              onPageChanged: (index) {
                setState(() {
                  currentIndex = index;
                });
              },
            )));
  }

  PhotoViewGalleryPageOptions buildView(BuildContext context, int idx) {
    var item = widget.items[idx];
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
          child: VideoPlayerWrapper(item.url, item.requestHeader));
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
    var item = widget.items[currentIndex];
    return AppBar(
      leading: IconButton(
        icon: Icon(Icons.arrow_back),
        onPressed: () => AppNav.pop(context),
      ),
      title: Text("($index/${widget.items.length})${item.name}"),
      actions: [buildMoreAction()],
    );
  }

  buildMoreAction() {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_horiz,
      ),
      itemBuilder: (context) {
        return [
          PopupMenuItem(
            child: Text("下载"),
            onTap: () => downloadCurrent(),
          ),
        ];
      },
    );
  }

  downloadCurrent() async {
    var item = widget.items[currentIndex];
    Downloader.platform.download(item.url);
    if (context.mounted) {
      AppMessage.show(context, "已开始下载, 请从状态栏查看下载进度");
    }
  }
}

class GalleryItem {
  String filepath;
  String? fileExt;
  String url;
  String name;
  Map<String, String> requestHeader;

  GalleryItem(
      {required this.filepath,
      this.fileExt,
      required this.url,
      required this.name,
      required this.requestHeader});
}
