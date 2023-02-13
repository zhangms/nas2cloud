import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ImageLoader {
  static ImageProvider cacheNetworkImageProvider(
      String url, Map<String, String> headers) {
    if (kIsWeb) {
      return NetworkImage(url, headers: headers);
    }
    return CachedNetworkImageProvider(url, headers: headers);
  }

  static Image cacheNetworkImage(String url, Map<String, String> headers) {
    return Image(image: cacheNetworkImageProvider(url, headers));
  }
}
