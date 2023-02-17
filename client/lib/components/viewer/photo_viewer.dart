import 'package:flutter/material.dart';
import 'package:nas2cloud/pub/image_loader.dart';
import 'package:photo_view/photo_view.dart';

class PhotoFullScreenViewer extends StatelessWidget {
  final String url;
  final Map<String, String>? headers;

  PhotoFullScreenViewer(this.url, this.headers);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: PhotoView(
            imageProvider:
                ImageLoader.cacheNetworkImageProvider(url, headers)));
  }
}
