import 'package:flutter/material.dart';

import 'file_list_view.dart';

class FileHome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FileListView(
      path: "/",
      pageSize: 50,
      fileHome: true,
      orderByInitValue: "fileName",
    );
  }
}
