import 'package:flutter/material.dart';
import 'package:nas2cloud/api/api.dart';
import 'package:nas2cloud/themes/widgets.dart';

class SplashPage extends StatefulWidget {
  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadServerStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(),
      body: buildBody(),
    );
  }

  buildAppBar() {
    return null;
  }

  buildBody() {
    if (errorMessage != null) {
      return AppWidgets.getPageErrorView(errorMessage!);
    }
    return Container();
  }

  Future<void> loadServerStatus() async {
    var resp = await Api().tryGetServerStatus();
    if (resp.message == "HOST_NOT_CONFIGED") {
      setState(() {
        Navigator.of(context).pushReplacementNamed("/config");
      });
      return;
    }
    if (!resp.success) {
      setState(() {
        errorMessage = resp.message;
      });
      return;
    }
    if (resp.data?.userName?.isEmpty ?? true) {
      setState(() {
        Navigator.of(context).pushReplacementNamed("/login");
      });
      return;
    }
    setState(() {
      Navigator.of(context).pushReplacementNamed("/home");
    });
  }
}
