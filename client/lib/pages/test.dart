import 'package:flutter/material.dart';
import 'package:nas2cloud/components/uploader/auto_uploader.dart';

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
    AutoUploader().executeAutoupload();
  }
}
