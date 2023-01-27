import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart' as filepath;

class TestPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(onPressed: () => onClick(), child: Text("CLICK"))
          ],
        ),
      ),
    );
  }

  onClick() async {
    var dir = await filepath.getExternalStorageDirectory();
    print("getExternalStorageDirectory");
    print(dir);

    var pics = await filepath.getExternalStorageDirectories(
        type: filepath.StorageDirectory.pictures);
    print("getExternalStorageDirectories");
    print(pics);

    var downloads = await filepath.getExternalStorageDirectories(
        type: filepath.StorageDirectory.downloads);
    print("getExternalStorageDirectories");
    print(downloads);

    // var download = await filepath.getDownloadsDirectory();
    // print("getDownloadsDirectory");
    // print(download);

    var appdoc = await filepath.getApplicationDocumentsDirectory();
    print("getApplicationDocumentsDirectory");
    print(appdoc);

    print("------");
    Directory directory = Directory("/storage/emulated/0/");
    var list = directory.listSync();
    for (var element in list) {
      print(element);
    }

    // getUploadRecord(taskId)
  }
}
