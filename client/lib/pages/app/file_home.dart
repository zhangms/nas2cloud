import 'package:flutter/material.dart';
import 'package:nas2cloud/api/api.dart';
import 'package:nas2cloud/api/file_walk_reqeust.dart';
import 'package:nas2cloud/api/file_walk_response/data.dart' as filewk;
import 'package:nas2cloud/api/file_walk_response/file.dart';
import 'package:nas2cloud/api/state_response/data.dart' as state;
import 'package:nas2cloud/app.dart';

class FileHomePage extends StatefulWidget {
  @override
  State<FileHomePage> createState() => _FileHomePageState();
}

class _FileHomePageState extends State<FileHomePage> {
  filewk.Data? walkData;

  @override
  void initState() {
    super.initState();
    initWalk();
  }

  @override
  Widget build(BuildContext context) {
    var hostState = appStorage.getHostState();
    return Scaffold(
      appBar: buildAppBar(hostState),
      body: SafeArea(child: Scrollbar(child: buildFileListView())),
    );
  }

  ListView buildFileListView() {
    int len = walkData?.files?.length ?? 0;
    return ListView(
      children: [
        for (int i = 0; i < len; i++) buildListItem(walkData!.files![i])
      ],
    );
  }

  ListTile buildListItem(File item) {
    return ListTile(
      leading: buildItemIcon(item),
      title: Text(item.name),
      subtitle: Text("${item.modTime}  ${item.size}"),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => Text(item.name),
          ),
        );
      },
    );
  }

  AppBar buildAppBar(state.Data? hostState) {
    var theme = Theme.of(context);
    return AppBar(
      backgroundColor: theme.primaryColor,
      leading: IconButton(
        icon: Icon(
          Icons.menu,
          color: theme.primaryIconTheme.color,
        ),
        onPressed: () {},
      ),
      title: Text(
        hostState?.appName ?? "Nas2cloud",
        style: theme.primaryTextTheme.titleMedium,
      ),
    );
  }

  Future<void> initWalk() async {
    FileWalkReqeust reqeust =
        FileWalkReqeust(path: "/", pageNo: 0, orderBy: "fileName");
    var resp = await api.postFileWalk(reqeust);
    if (!resp.success || resp.data == null) {
      print("walk file error:${resp.toString()}");
      return;
    }
    setState(() {
      walkData = resp.data;
    });
  }

  Widget? buildItemIcon(File item) {
    if (item.type == "DIR") {
      return Icon(Icons.folder);
    }
    return Icon(Icons.insert_drive_file);
  }
}
