import 'package:flutter/material.dart';
import 'package:nas2cloud/pub/image_loader.dart';

import '../../api/api.dart';
import '../../dto/file_walk_response.dart';
import '../../utils/file_helper.dart';

class FileWidgets {
  static Widget getItemIcon(FileWalkResponseDataFiles item) {
    if (item.type == "DIR") {
      return Icon(Icons.folder);
    }
    if (item.thumbnail == null || item.thumbnail!.isEmpty) {
      return _getItemIconByExt(item.ext);
    }
    if (FileHelper.isVideo(item.ext)) {
      return _getItemThumbnailVideo(item.thumbnail!);
    }
    return _getItemThumbnail(item.thumbnail!);
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
    if (FileHelper.isDoc(ext)) {
      return Icon(Icons.summarize);
    }

    switch (ext) {
      case ".TXT":
        return Icon(Icons.text_snippet);
      default:
        return Icon(Icons.insert_drive_file);
    }
  }

  static Widget _getItemThumbnailVideo(String thumb) {
    return SizedBox(
      child: Stack(
        alignment: Alignment.center,
        children: [
          _getItemThumbnail(thumb),
          Icon(
            Icons.play_circle,
            color: Colors.white,
          )
        ],
      ),
    );
  }

  static Widget _getItemThumbnail(String thumb) {
    return Padding(
      padding: const EdgeInsets.only(top: 5, bottom: 5),
      child: SizedBox(
        height: 40,
        width: 40,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: FutureBuilder<Widget>(
              future: _buildImage(thumb),
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
    return ImageLoader.cacheNetworkImage(url, headers);
  }
}
