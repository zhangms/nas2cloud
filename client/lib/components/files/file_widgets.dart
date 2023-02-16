import 'package:flutter/material.dart';
import 'package:nas2cloud/pub/image_loader.dart';

import '../../api/api.dart';
import '../../api/dto/file_walk_response/file.dart';
import '../../utils/file_helper.dart';

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

  static Widget _getItemThumbnailVideo(File item) {
    return SizedBox(
      child: Stack(
        alignment: Alignment.center,
        children: [
          _getItemThumbnail(item),
          Icon(
            Icons.play_circle,
            size: 36,
            color: Color.fromARGB(128, 22, 212, 111),
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
    return ImageLoader.cacheNetworkImage(url, headers);
  }
}
