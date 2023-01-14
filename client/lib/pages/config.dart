import 'package:flutter/material.dart';
import 'package:nas2cloud/api/api.dart';
import 'package:nas2cloud/app.dart';
import 'package:nas2cloud/utils/adaptive.dart';
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
    var response = await api.stateByHost(address);
    if (response.success) {
      clearError();
      appState.saveHostAddress(address);
    } else {
      error(message: response.message ?? "ERROR");
    }
  }
}
