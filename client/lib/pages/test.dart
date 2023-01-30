import 'package:flutter/material.dart';
import 'package:nas2cloud/components/uploader/auto_upload_config.dart';
import 'package:nas2cloud/components/uploader/auto_uploader.dart';
import 'package:nas2cloud/components/uploader/upload_repo.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';

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
    UploadRepository.platform.clearAll();

    await AutoUploader().saveConfig(AutoUploadConfig(
        name: "Download",
        path: "/storage/emulated/0/Download",
        basepath: "/storage/emulated/0",
        remote: "/userhome_zms",
        autoupload: true));
    if (await Permission.manageExternalStorage.request().isGranted) {
      AutoUploader().executeAutoupload();
    }

    var f = "/storage/emulated/0/";
    var b = "/storage/emulated/0/";

    var r = p.relative(f, from: b);
    print("relative------>$r");
    var remote = "/home";
    print(p.normalize(p.join(remote, r)));
  }
}
