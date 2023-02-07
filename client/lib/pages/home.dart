import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nas2cloud/api/api.dart';
import 'package:nas2cloud/api/app_config.dart';
import 'package:nas2cloud/api/dto/state_response/state_response.dart';
import 'package:nas2cloud/components/files/file_home.dart';
import 'package:nas2cloud/components/uploader/file_uploder.dart';
import 'package:nas2cloud/event/bus.dart';
import 'package:nas2cloud/event/event_logout.dart';
import 'package:nas2cloud/pages/home_drawer.dart';
import 'package:nas2cloud/themes/app_nav.dart';

import '../themes/widgets.dart';

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late StreamSubscription<EventLogout> subscription;

  @override
  void initState() {
    super.initState();
    subscription = eventBus.on<EventLogout>().listen((event) {
      logout();
    });
  }

  @override
  void dispose() {
    subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(),
      drawer: Drawer(
        child: SafeArea(
          child: HomeDrawer(),
        ),
      ),
      body: buildBody(),
    );
  }

  buildAppBar() {
    return AppBar(
      leading: Builder(builder: (context) {
        return IconButton(
          icon: Icon(Icons.menu),
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
        );
      }),
      title: AppWidgets.getAppNameText(),
    );
  }

  buildBody() {
    return FutureBuilder<StateResponse>(
        future: Api().tryGetServerStatus(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return AppWidgets.pageLoadingView();
          }
          var status = snapshot.data!;
          if (!status.success) {
            return AppWidgets.pageErrorView(status.message!);
          }
          if (status.data?.userName?.isEmpty ?? true) {
            return buildLoginRequired();
          }
          return FileHomePage();
        });
  }

  logout() async {
    await FileUploader.platform.cancelAllRunning();
    await AppConfig.clearUserLogin();
    setState(() {
      AppNav.goLogin(context);
    });
  }

  buildLoginRequired() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("登录已过期，需要重新登录"),
          SizedBox(height: 16),
          ElevatedButton(onPressed: () => logout(), child: Text("重新登录")),
        ],
      ),
    );
  }
}
