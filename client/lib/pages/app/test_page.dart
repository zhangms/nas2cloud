import 'package:flutter/material.dart';

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
    // var process = Random().nextInt(100);

    // LocalNotification.get()
    //     .send(id: "id", title: "上传：AAA.png", body: "$process%");
  }
}
