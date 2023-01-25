import 'package:flutter/foundation.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:nas2cloud/api/api.dart';
import 'package:url_launcher/url_launcher.dart';

class Downloader {
  static void download(String path) {
    if (kIsWeb) {
      launchUrl(Uri.parse(Api.signUrl(path)));
    } else {
      FlutterDownloader.enqueue(
        url: path,
        headers: Api.httpHeaders(),
        savedDir: "./",
        saveInPublicStorage: true,
        showNotification: true,
        openFileFromNotification: true,
      );
    }
  }
}
