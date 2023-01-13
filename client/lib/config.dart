import 'package:flutter/material.dart';
import 'package:nas2cloud/layout/adaptive.dart';

class ConfigPage extends StatefulWidget {
  @override
  State<ConfigPage> createState() => _ConfigPageState();
}

class _ConfigPageState extends State<ConfigPage> {
  var addressTextController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: screenMainAreaWidth(context: context),
        child: TextField(
          controller: addressTextController,
          decoration: InputDecoration(
              labelText: "服务器地址",
              suffixIcon: IconButton(
                  onPressed: (() {
                    onNext(context: context);
                  }),
                  icon: Icon(Icons.arrow_forward))),
          onSubmitted: (value) {
            onNext(context: context);
          },
        ),
      ),
    );
  }

  onNext({required BuildContext context}) {
    var address = addressTextController.text;
    if (!address.startsWith("http://")) {
      address = "http://$address";
    }
    print("address:$address");
    
  }
}
