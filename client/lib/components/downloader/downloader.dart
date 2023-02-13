import 'package:flutter/foundation.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';

import '../../api/api.dart';

class Downloader {
  static Downloader _instance = Downloader._private();

  static Downloader get platform => _instance;

  Downloader._private();

  Future<void> download(String path) async {
    if (kIsWeb) {
      var url = await Api().signUrl(path);
      launchUrl(Uri.parse(url));
    } else {
      var fileName = p.basename(path);
      var headers = await Api().httpHeaders();
      FlutterDownloader.enqueue(
        url: path,
        headers: headers,
        savedDir: "./",
        fileName: fileName,
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

  Future<void> initialize() async {
    if (kIsWeb) {
      return;
    }
    if (_inited) {
      return;
    }
    _inited = true;
    await FlutterDownloader.initialize(debug: kDebugMode, ignoreSsl: true);
    await FlutterDownloader.registerCallback(downloadCallback);
    print("FlutterDownloader init complete");
  }
}
