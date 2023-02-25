import 'package:flutter/material.dart';
import 'package:nas2cloud/api/api.dart';
import 'package:nas2cloud/components/files/file_widgets.dart';
import 'package:nas2cloud/pub/widgets.dart';

import '../../dto/search_photo_response.dart';

class TimelinePhotoGridView extends StatefulWidget {
  @override
  State<TimelinePhotoGridView> createState() => _TimelinePhotoGridViewState();
}

class _TimelinePhotoGridViewState extends State<TimelinePhotoGridView> {
  static const int crossAxisCount = 8;

  String searchAfter = "";
  bool noMoreData = false;
  List<SearchPhotoResponseDataFiles> files = [];

  @override
  void initState() {
    super.initState();
    searchPhoto(searchAfter);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(context),
      body: buildBody(context),
    );
  }

  buildAppBar(BuildContext context) {
    return AppBar(
      leading: AppWidgets.appBarArrowBack(context),
      title: Text("照片"),
    );
  }

  buildBody(BuildContext context) {
    return GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 1,
          crossAxisSpacing: 1,
        ),
        itemBuilder: (context, index) => buildItem(context, index));
  }

  Widget? buildItem(BuildContext context, int index) {
    if (files.length <= index) {
      return null;
    }
    var item = files[index];
    return FutureBuilder<Widget>(
        future: FileWidgets.buildImage(
            item.thumbnail ?? "/assets/default_thumb.jpg"),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return snapshot.data!;
          }
          return Container();
        });
  }

  Future<void> searchPhoto(String searchAfter) async {
    SearchPhotoResponse response = await Api().searchPhoto(searchAfter);
    if (!response.success) {
      print(response.toJson());
      return;
    }
    if (response.data == null) {
      return;
    }
    SearchPhotoResponseData data = response.data!;
    var dataFiles = data.files ?? [];
    setState(() {
      searchAfter = data.searchAfter;
      files.addAll(dataFiles);
    });
  }
}
