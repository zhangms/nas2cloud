import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:nas2cloud/app.dart';
import 'package:nas2cloud/layout/adaptive.dart';
import 'package:provider/provider.dart';

class ConfigPage extends StatefulWidget {
  @override
  State<ConfigPage> createState() => _ConfigPageState();
}

class _ConfigPageState extends State<ConfigPage> {
  var addressTextController = TextEditingController();
  var errorMessage = "";

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<AppState>();
    return Center(
      child: SizedBox(
        width: screenMainAreaWidth(context: context),
        child: TextField(
          controller: addressTextController,
          decoration: InputDecoration(
              errorText: errorMessage,
              labelText: "服务器地址",
              suffixIcon: IconButton(
                  onPressed: (() {
                    onNext(appState);
                  }),
                  icon: Icon(Icons.arrow_forward))),
          onSubmitted: (value) {
            onNext(appState);
          },
          onChanged: (value) {
            clearError();
          },
        ),
      ),
    );
  }

  error({required String message}) {
    setState(() {
      errorMessage = message;
    });
  }

  clearError() {
    setState(() {
      errorMessage = "";
    });
  }

  onNext(AppState appState) async {
    var address = addressTextController.text;
    if (address.startsWith("http://")) {
      address = address.substring("http://".length);
    }
    print("address:$address");
    try {
      var url = Uri.http(address, "api/state");
      var response = await http.get(url);
      if (response.statusCode != 200) {
        error(message: "服务器状态错误:${response.statusCode}");
        return;
      }
      clearError();
      appState.setHostAddress("http://$address");
    } catch (e) {
      error(message: "无法连接");
    }
  }
}
