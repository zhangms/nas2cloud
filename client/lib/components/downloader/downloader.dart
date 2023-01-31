import 'package:flutter/foundation.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:nas2cloud/api/api.dart';
import 'package:url_launcher/url_launcher.dart';

class Downloader {
  static Downloader _instance = Downloader._private();

  static Downloader get platform => _instance;

  Downloader._private();

  Future<void> download(String path) async {
    if (kIsWeb) {
      var url = await Api.signUrl(path);
      launchUrl(Uri.parse(url));
    } else {
      var headers = await Api.httpHeaders();
      FlutterDownloader.enqueue(
        url: path,
        headers: headers,
        savedDir: "./",
        saveInPublicStorage: true,
        showNotification: true,
        openFileFromNotification: true,
      );
    }
  }

  @pragma('vm:entry-point')
  static void downloadCallback(
      String id, DownloadTaskStatus status, int progress) {
    print("downloadCallback $id, $status, $progress");
  }

  static bool _inited = false;

  Future<bool> initialize() async {
    if (kIsWeb) {
      return true;
    }
    if (_inited) {
      return true;
    }
    _inited = true;
    await FlutterDownloader.initialize(debug: isInDebugMode, ignoreSsl: true);
    FlutterDownloader.registerCallback(downloadCallback);
    print("FlutterDownloader init complete");
    return true;
  }
}
