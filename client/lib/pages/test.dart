import 'package:flutter/material.dart';

import '../api/api.dart';
import '../api/app_config.dart';
import '../components/files/file_list_page.dart';
import '../components/notification/notification.dart';
import '../components/uploader/auto_uploader.dart';
import '../components/uploader/file_uploader.dart';
import '../components/uploader/upload_repo.dart';
import '../dto/auto_upload_config.dart';
import '../dto/login_response.dart';
import '../dto/state_response.dart';
import '../pub/app_nav.dart';

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
                ElevatedButton(onPressed: () => login(), child: Text("LOGIN")),
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
    AppNav.gohome(context);
  }

  mock() async {
    LocalNotification.platform.send(id: 1, title: "Hello", body: "world");

    await AppConfig.useMockApi(true);
    await AppConfig.saveServerAddress("192.168.31.88:8080");
    await AppConfig.saveUserLoginInfo(LoginResponseData(
        username: "zms",
        token: "zms-123",
        createTime: DateTime.now().toString()));
    await AppConfig.saveServerStatus(StateResponseData(
      appName: "HELLO",
      publicKey: "",
      userName: "zms",
      userAvatar:
          "http://beebot-pri.oss-cn-beijing.aliyuncs.com/zms/mark/qrcode_stackoverflow.com.png",
      userAvatarLarge:
          "http://beebot-pri.oss-cn-beijing.aliyuncs.com/zms/mark/qrcode_stackoverflow.com.png",
    ));
    AppConfig.setThemeSetting(AppConfig.themeLight);
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
    // AppNav.openPage(context, SettingPage());
    // var start = DateTime.now();
    // if (await Permission.manageExternalStorage.request().isGranted) {
    //   await BackgroundProcessor().executeOnceAutoUploadTask();
    //   print(
    //       "executeUpload-->${DateTime.now().difference(start).inMilliseconds}");
    // }
    AppNav.openPage(context, FileListPage("/home", "TEST"));
  }

  initUploadData() async {
    var config = AutoUploadConfig(
        name: "Download",
        path: "/storage/emulated/0/Download",
        basepath: "/storage/emulated/0",
        remote: "/Pic",
        autoupload: true);
    await AutoUploader().saveConfig(config);

    // for (var state in UploadStatus.values) {
    //   for (var i = 0; i < 2; i++) {
    //     var entry = FileUploader.createEntryByFilepath(
    //         channel: config.uploadChannel,
    //         filepath: "${config.path}/${state.name}_$i.png",
    //         relativeFrom: config.basepath,
    //         remote: "/abc");
    //     entry.status = state.name;
    //     await UploadRepository.platform.saveIfNotExists(entry);
    //   }
    // }
  }

  clean() async {
    await FileUploader.platform.cancelAllRunning();
    await UploadRepository.platform.clearAll();
    await AutoUploader().clearConfig();
    await AppConfig.useMockApi(false);
    await AppConfig.clearUserLogin();
    await AppConfig.clearServerAddress();
  }

  login() async {
    await AppConfig.saveServerAddress("192.168.31.88:8080");
    var resp = await Api().postLogin(username: "zms", password: "baobao4321x");
    await AppConfig.saveUserLoginInfo(resp.data!);
    await Api().tryGetServerStatus();
  }
}
