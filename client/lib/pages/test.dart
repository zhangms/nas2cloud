import 'package:flutter/material.dart';
import 'package:nas2cloud/components/notification/notification.dart';

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
    LocalNotification.platform.send(id: 1, title: "Hello", body: "world");

    // UploadRepository.platform.clearAll();

    // await AppConfig.saveHostAddress("192.168.31.175:8080");

    // await AutoUploader().saveConfig(AutoUploadConfig(
    //     name: "Download",
    //     path: "/storage/emulated/0/Download",
    //     basepath: "/storage/emulated/0",
    //     remote: "/userhome_zms",
    //     autoupload: true));
    // if (await Permission.manageExternalStorage.request().isGranted) {
    //   AutoUploader().executeAutoupload();
    // }

    // var f = "/storage/emulated/0/";
    // var b = "/storage/emulated/0/";

    // var r = p.relative(f, from: b);
    // print("relative------>$r");
    // var remote = "/home";
    // print(p.normalize(p.join(remote, r)));
  }
}
