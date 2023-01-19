import 'package:flutter/material.dart';
import 'package:nas2cloud/api/api.dart';
import 'package:nas2cloud/api/file_walk_response/file.dart';

class _FileExt {
  bool isImage(String? ext) {
    if (ext == null) {
      return false;
    }
    switch (ext) {
      case ".JPG":
      case ".JPEG":
      case ".PNG":
        return true;
      default:
        return false;
    }
  }

  bool isMusic(String? ext) {
    if (ext == null) {
      return false;
    }
    switch (ext) {
      case ".MP3":
      case ".WAV":
        return true;
      default:
        return false;
    }
  }

  bool isVideo(String? ext) {
    if (ext == null) {
      return false;
    }
    switch (ext) {
      case ".MP4":
      case ".MOV":
        return true;
      default:
        return false;
    }
  }

  Widget getItemIcon(File item) {
    if (item.type == "DIR") {
      return Icon(Icons.folder);
    }
    if (item.thumbnail == null || item.thumbnail!.isEmpty) {
      return _getItemIconByExt(item.ext);
    }
    if (isVideo(item.ext)) {
      return _getItemThumbnailVideo(item);
    }
    return _getItemThumbnail(item);
  }

  Widget _getItemIconByExt(String? ext) {
    if (isImage(ext)) {
      return Icon(Icons.image);
    }
    if (isMusic(ext)) {
      return Icon(Icons.audio_file);
    }
    if (isVideo(ext)) {
      return Icon(Icons.video_file);
    }
    return Icon(Icons.insert_drive_file);
  }

  Widget _getItemThumbnailVideo(File item) {
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

  Padding _getItemThumbnail(File item) {
    return Padding(
      padding: const EdgeInsets.only(top: 5, bottom: 5),
      child: SizedBox(
        height: 40,
        width: 40,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: Image.network(
            api.getStaticFileUrl(item.thumbnail!),
            headers: api.httpHeaders(),
          ),
        ),
      ),
    );
  }
}

var fileExt = _FileExt();
