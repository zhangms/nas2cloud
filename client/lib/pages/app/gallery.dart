import 'package:flutter/material.dart';
import 'package:nas2cloud/api/api.dart';
import 'package:nas2cloud/api/file_walk_response/file.dart';
import 'package:nas2cloud/app.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class GalleryPhotoViewPage extends StatefulWidget {
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
          decoration: const BoxDecoration(
            color: Colors.black,
          ),
          constraints: BoxConstraints.expand(
            height: MediaQuery.of(context).size.height,
          ),
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              PhotoViewGallery.builder(
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
              )
            ],
          ),
        ));
  }

  PhotoViewGalleryPageOptions buildImage(BuildContext context, int idx) {
    File item = widget.images[idx];
    return PhotoViewGalleryPageOptions(
        imageProvider: NetworkImage(appStorage.getStaticFileUrl(item.path),
            headers: api.httpHeaders()),
        initialScale: PhotoViewComputedScale.contained,
        minScale: PhotoViewComputedScale.contained * 0.5,
        maxScale: PhotoViewComputedScale.covered * 4.1,
        heroAttributes: PhotoViewHeroAttributes(tag: item.path),
        controller: controller,
        scaleStateController: scaleStateController);
  }

  buildAppBar() {
    var theme = Theme.of(context);
    var index = currentIndex + 1;
    return AppBar(
      backgroundColor: theme.primaryColor,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back,
          color: theme.primaryIconTheme.color,
        ),
        onPressed: () {
          Navigator.of(context).pop();
        },
      ),
      title: Text(
        "$index/${widget.images.length}",
        style: theme.primaryTextTheme.titleMedium,
      ),
    );
  }
}
