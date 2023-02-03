import 'package:flutter/material.dart';
import 'package:nas2cloud/api/api.dart';
import 'package:nas2cloud/api/app_config.dart';
import 'package:nas2cloud/themes/app_nav.dart';
import 'package:nas2cloud/utils/adaptive.dart';

class ConfigPage extends StatefulWidget {
  @override
  State<ConfigPage> createState() => _ConfigPageState();
}

class _ConfigPageState extends State<ConfigPage> {
  var addressTextController = TextEditingController();
  var errorMessage = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppConfig.defaultAppName),
      ),
      body: Center(
        child: SizedBox(
          width: screenMainAreaWidth(context: context),
          child: TextField(
            controller: addressTextController,
            decoration: InputDecoration(
                errorText: errorMessage,
                labelText: "服务器地址",
                suffixIcon: IconButton(
                    onPressed: (() => onNext()),
                    icon: Icon(Icons.arrow_forward))),
            onSubmitted: (value) => onNext(),
            onChanged: (value) => clearError(),
          ),
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

  onNext() async {
    var address = addressTextController.text;
    if (address.startsWith("http://")) {
      address = address.substring("http://".length);
    }
    print("address:$address");
    var response = await Api().getServerStatus(address);
    if (response.success) {
      await AppConfig.saveServerAddress(address);
      await AppConfig.saveServerStatus(response.data!);
      setState(() {
        errorMessage = "";
        AppNav.goLogin(context);
      });
    } else {
      error(message: response.message ?? "ERROR");
    }
  }
}
