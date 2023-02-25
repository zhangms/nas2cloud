import 'package:flutter/material.dart';
import 'package:nas2cloud/pub/widgets.dart';

class TimelinePhotoGridView extends StatefulWidget {
  @override
  State<TimelinePhotoGridView> createState() => _TimelinePhotoGridViewState();
}

class _TimelinePhotoGridViewState extends State<TimelinePhotoGridView> {
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
          crossAxisCount: 8,
          mainAxisSpacing: 1,
          crossAxisSpacing: 1,
        ),
        itemBuilder: (context, index) => buildItem(context, index));
  }

  Widget? buildItem(BuildContext context, int index) {
    if (index % 24 == 0) {
      return Align(alignment: Alignment.bottomLeft, child: Text("2023-02"));
    }
    if (index % 24 < 8) {
      return Container();
    }
    return Container(
      color: Colors.blue,
      child: Text("$index"),
    );
  }
}
