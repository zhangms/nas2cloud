import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nas2cloud/api/api.dart';
import 'package:nas2cloud/api/dto/file_walk_response/file.dart';
import 'package:nas2cloud/components/gallery/pdf_viewer.dart';
import 'package:nas2cloud/components/gallery/text_reader.dart';
import 'package:nas2cloud/components/gallery/video_player.dart';
import 'package:nas2cloud/themes/widgets.dart';
import 'package:nas2cloud/utils/file_helper.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class GalleryPhotoViewPage extends StatefulWidget {
  static bool isSupportFileExt(String? ext) {
    if (FileHelper.isImage(ext) || FileHelper.isVideo(ext)) {
      return true;
    }
    if (!kIsWeb && FileHelper.isPDF(ext)) {
      return true;
    }
    if (FileHelper.isText(ext)) {
      return true;
    }
    return false;
  }

  final List<File> images;
  final int index;
  final PageController pageController;

  GalleryPhotoViewPage(this.images, this.index)
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
            backgroundDecoration:
                BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor),
            scrollPhysics: const BouncingScrollPhysics(),
            pageController: widget.pageController,
            itemCount: widget.images.length,
            scrollDirection: Axis.horizontal,
            builder: buildImage,
            onPageChanged: (index) {
              setState(() {
                currentIndex = index;
              });
            },
          ),
        ));
  }

  PhotoViewGalleryPageOptions buildImage(BuildContext context, int idx) {
    File item = widget.images[idx];
    if (FileHelper.isImage(item.ext)) {
      return PhotoViewGalleryPageOptions(
          imageProvider: NetworkImage(Api.getStaticFileUrl(item.path),
              headers: Api.httpHeaders()),
          initialScale: PhotoViewComputedScale.contained,
          minScale: PhotoViewComputedScale.contained * 0.5,
          maxScale: PhotoViewComputedScale.covered * 4.1,
          heroAttributes: PhotoViewHeroAttributes(tag: item.path),
          controller: controller,
          scaleStateController: scaleStateController);
    } else if (FileHelper.isVideo(item.ext)) {
      return PhotoViewGalleryPageOptions.customChild(
          child: VideoPlayerWapper(Api.getStaticFileUrl(item.path)));
    } else if (FileHelper.isPDF(item.ext)) {
      return PhotoViewGalleryPageOptions.customChild(
          child: PDFViewer(Api.getStaticFileUrl(item.path)));
    } else if (FileHelper.isText(item.ext)) {
      return PhotoViewGalleryPageOptions.customChild(
          child: TextReader(path: item.path));
    } else {
      return PhotoViewGalleryPageOptions.customChild(
          child: AppWidgets.getPageErrorView("UNSUPPORT"));
    }
  }

  buildAppBar() {
    var index = currentIndex + 1;
    var item = widget.images[currentIndex];
    return AppBar(
      leading: IconButton(
        icon: Icon(Icons.arrow_back),
        onPressed: () {
          Navigator.of(context).pop();
        },
      ),
      title: Text("($index/${widget.images.length})${item.name}"),
    );
  }
}
