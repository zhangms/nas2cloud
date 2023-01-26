import 'package:flutter/material.dart';
import 'package:nas2cloud/api/api.dart';

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
    Api.rangeGetStatic(
            "/Docs/pro2012001/trunk/extjtemp/project/src/ext/jtemp/aa/eo/EOAAMenuToUserGroup.java",
            0,
            1000)
        .then((value) => {print(value)});
  }
}
