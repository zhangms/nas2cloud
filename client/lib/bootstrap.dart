import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_uploader/flutter_uploader.dart';
import 'package:nas2cloud/utils/spu.dart';

void _flutterUploaderBackgroudHandler() {
  // Needed so that plugin communication works.
  // This uploader instance works within the isolate only.
  FlutterUploader uploader = FlutterUploader();

  // You have now access to:
  uploader.progress.listen((progress) {
    // upload progress
  });
  uploader.result.listen((result) {
    // upload results
  });
}

void downloadCallback(String id, DownloadTaskStatus status, int progress) {
  print("downloadCallback $id, $status, $progress");
}

initBeforeRunApp() async {
  var prefComplete = await spu.initSharedPreferences();
  if (!prefComplete) {
    throw Error.safeToString("initSharedPreferences error");
  }
  print("SharedPreferences init complete");
  if (kIsWeb) {
    return;
  }
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterDownloader.initialize(debug: true, ignoreSsl: true);
  FlutterDownloader.registerCallback(downloadCallback);

  print("FlutterDownloader init complete");
  FlutterUploader().setBackgroundHandler(_flutterUploaderBackgroudHandler);
  print("FlutterUploader init complete");
}
