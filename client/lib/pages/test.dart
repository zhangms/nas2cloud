import 'package:flutter/material.dart';
import 'package:flutter_uploader/flutter_uploader.dart';
import 'package:nas2cloud/components/notification/notification.dart';
import 'package:nas2cloud/components/uploader/upload_repo.dart';
import 'package:permission_handler/permission_handler.dart';

import '../components/uploader/auto_upload_config.dart';
import '../components/uploader/auto_uploader.dart';

class TestPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(onPressed: () => reset(), child: Text("RESET")),
            SizedBox(
              height: 10,
            ),
            ElevatedButton(onPressed: () => exec(), child: Text("EXEC"))
          ],
        ),
      ),
    );
  }

  reset() async {
    LocalNotification.platform.send(id: 1, title: "Hello", body: "world");

    await FlutterUploader().cancelAll();
    await FlutterUploader().clearUploads();

    var clearCount = await UploadRepository.platform.clearAll();
    print("UploadRepository clearAll : $clearCount");
  }

  exec() async {
    // await AppConfig.saveHostAddress("192.168.31.175:8080");
    await AutoUploader().saveConfig(AutoUploadConfig(
        name: "Download",
        path: "/storage/emulated/0/Download",
        basepath: "/storage/emulated/0",
        remote: "/userhome_zms",
        autoupload: true));
    if (await Permission.manageExternalStorage.request().isGranted) {
      AutoUploader().executeAutoupload();
    }
  }
}
