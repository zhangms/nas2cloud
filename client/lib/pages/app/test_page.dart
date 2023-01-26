import 'package:encrypt/encrypt.dart';
import 'package:flutter/material.dart';
import 'package:nas2cloud/api/app_storage.dart';
import 'package:pointycastle/asymmetric/api.dart';

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

  onClick() {
    var parser = RSAKeyParser();
    String key = AppStorage.getHostState()?.publicKey ?? "";
    var publicKey = parser.parse(key) as RSAPublicKey;
    print(publicKey);

    final encrypter = Encrypter(RSA(publicKey: publicKey));

    var str =
        '1674747199326 {"X-DEVICE":"flutter-app-web","Content-Type":"application/json;charset=UTF-8","X-AUTH-TOKEN":"zms-c71656ba-185f-4736-97a3-4dae205907ba"}';

    for (var i = 0; i < str.length; i++) {
      var s = str.substring(i);
      try {
        final encrypted = encrypter.encrypt(s);
        print(encrypted.base64);
        print("OK--->${s.length}");
        break;
      } catch (e) {
        print("$e, ${s.length}");
      }
    }

    // var process = Random().nextInt(100);

    // LocalNotification.get()
    //     .send(id: "id", title: "上传：AAA.png", body: "$process%");
  }
}
