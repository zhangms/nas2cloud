import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:nas2cloud/api/api.dart';
import 'package:nas2cloud/api/dto/file_walk_response/file.dart';
import 'package:nas2cloud/utils/file_helper.dart';

class FileWidgets {
  static Widget getItemIcon(File item) {
    if (item.type == "DIR") {
      return Icon(Icons.folder);
    }
    if (item.thumbnail == null || item.thumbnail!.isEmpty) {
      return _getItemIconByExt(item.ext);
    }
    if (FileHelper.isVideo(item.ext)) {
      return _getItemThumbnailVideo(item);
    }
    return _getItemThumbnail(item);
  }

  static Widget _getItemIconByExt(String? ext) {
    if (FileHelper.isImage(ext)) {
      return Icon(Icons.image);
    }
    if (FileHelper.isMusic(ext)) {
      return Icon(Icons.audio_file);
    }
    if (FileHelper.isVideo(ext)) {
      return Icon(Icons.video_file);
    }
    if (FileHelper.isPDF(ext)) {
      return Icon(Icons.picture_as_pdf);
    }
    switch (ext) {
      case ".TXT":
        return Icon(Icons.text_snippet);
      default:
        return Icon(Icons.insert_drive_file);
    }
  }

  static Widget _getItemThumbnailVideo(File item) {
    return SizedBox(
      height: 40,
      width: 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _getItemThumbnail(item),
          Icon(
            Icons.play_arrow,
          )
        ],
      ),
    );
  }

  static Widget _getItemThumbnail(File item) {
    return Padding(
      padding: const EdgeInsets.only(top: 5, bottom: 5),
      child: SizedBox(
        height: 40,
        width: 40,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: FutureBuilder<Widget>(
              future: _buildImage(item.thumbnail!),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return snapshot.data!;
                }
                return Text("");
              }),
        ),
      ),
    );
  }

  static Future<Widget> _buildImage(String thumbnail) async {
    var url = await Api().getStaticFileUrl(thumbnail);
    var headers = await Api().httpHeaders();
    return Image(image: CachedNetworkImageProvider(url, headers: headers));
  }
}
