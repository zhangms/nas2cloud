import 'package:flutter/material.dart';
import 'package:nas2cloud/api/app_config.dart';
import 'package:nas2cloud/api/dto/login_response/data.dart' as userdata;
import 'package:nas2cloud/api/dto/state_response/data.dart' as statdata;
import 'package:nas2cloud/components/notification/notification.dart';
import 'package:nas2cloud/components/uploader/auto_upload_config.dart';
import 'package:nas2cloud/components/uploader/auto_uploader.dart';
import 'package:nas2cloud/components/uploader/file_uploder.dart';
import 'package:nas2cloud/components/uploader/upload_repo.dart';
import 'package:nas2cloud/components/uploader/upload_status.dart';

class TestPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(onPressed: () => mock(), child: Text("MOCK")),
                SizedBox(
                  width: 30,
                ),
                ElevatedButton(onPressed: () => clean(), child: Text("CLEAN")),
              ],
            ),
            SizedBox(
              height: 20,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                    onPressed: () => exec(context), child: Text("EXEC")),
                SizedBox(
                  width: 30,
                ),
                ElevatedButton(
                    onPressed: () => gohome(context), child: Text("HOME")),
              ],
            )
          ],
        ),
      ),
    );
  }

  gohome(BuildContext context) {
    var nav = Navigator.of(context);
    nav.pushNamedAndRemoveUntil("/home", ModalRoute.withName('/'));
  }

  mock() async {
    LocalNotification.platform.send(id: 1, title: "Hello", body: "world");
    await saveAppState();
    await initUploadData();
  }

  void autoupload() {
    // await AutoUploader().saveConfig(AutoUploadConfig(
    //     name: "Download",
    //     path: "/storage/emulated/0/Download",
    //     basepath: "/storage/emulated/0",
    //     remote: "/userhome_zms",
    //     autoupload: true));
    // if (await Permission.manageExternalStorage.request().isGranted) {
    //   AutoUploader().executeAutoupload();
    // }
  }

  exec(BuildContext context) async {
    // Navigator.of(context).push(
    //   MaterialPageRoute(
    //     builder: (context) => FileUploadTaskPage(),
    //   ),
    // );

    // FlutterUploader().progress.forEach((element) {
    //   print("uploader-->$element");
    // });
    AutoUploader().executeAutoupload();
  }

  saveAppState() async {
    await AppConfig.saveHostAddress("192.168.31.175:8080");
    var hostAddress = await AppConfig.getHostAddress();
    print("hostAddress---->$hostAddress");
    await AppConfig.saveUserLoginInfo(userdata.Data(
        username: "zms",
        token: "zms-123",
        createTime: DateTime.now().toString()));
    var loginInfo = await AppConfig.getUserLoginInfo();
    print("loginInfo--->$loginInfo");
    await AppConfig.saveHostState(statdata.Data(
      appName: "HELLO",
      publicKey: "",
      userName: "zms",
    ));
    var hoststate = await AppConfig.getHostState();
    print("hoststate------>$hoststate");
    await AppConfig.useMockApi(true);
    print("mockapi------>${AppConfig.isUseMockApi()}");
  }

  initUploadData() async {
    await FileUploader.platform.cancelAndClearAll();

    var config = AutoUploadConfig(
        name: "Download",
        path: "/storage/emulated/0/Download",
        basepath: "/storage/emulated/0",
        remote: "/abc",
        autoupload: true);
    AutoUploader().saveConfig(config);

    for (var state in UploadStatus.values) {
      for (var i = 0; i < 2; i++) {
        var entry = FileUploader.toUploadEntry(
            channel: config.uploadChannel,
            filepath: "${config.path}/${state.name}_$i.png",
            relativeFrom: config.basepath,
            remote: "/abc");
        entry.status = state.name;
        await UploadRepository.platform.saveIfNotExists(entry);
      }
    }
  }

  clean() async {
    await FileUploader.platform.cancelAndClearAll();
    await AutoUploader().clearConfig();
    await AppConfig.useMockApi(false);
    await AppConfig.clearUserLogin();
    await AppConfig.clearHostAddress();
  }
}
