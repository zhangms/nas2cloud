import 'package:flutter/material.dart';
import 'package:nas2cloud/api/app_config.dart';
import 'package:nas2cloud/api/dto/login_response/data.dart' as userdata;
import 'package:nas2cloud/api/dto/state_response/data.dart' as statdata;
import 'package:nas2cloud/components/notification/notification.dart';
import 'package:nas2cloud/components/uploader/file_uploder.dart';
import 'package:nas2cloud/components/uploader/pages/page_file_upload_task.dart';
import 'package:nas2cloud/components/uploader/upload_repo.dart';

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
            ElevatedButton(onPressed: () => exec(context), child: Text("EXEC"))
          ],
        ),
      ),
    );
  }

  reset() async {
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
    LocalNotification.platform.send(id: 1, title: "Hello", body: "world");
    await FileUploader.platform.clearAll();
    var clearCount = await UploadRepository.platform.clearAll();
    print("UploadRepository clearAll : $clearCount");
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
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FileUploadTaskPage(),
      ),
    );
  }
}
