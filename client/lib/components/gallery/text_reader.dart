import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:nas2cloud/api/api.dart';
import 'package:nas2cloud/themes/widgets.dart';

class TextReader extends StatefulWidget {
  final String url;
  final Map<String, String> requestHeader;

  TextReader(this.url, this.requestHeader);

  @override
  State<TextReader> createState() => _TextReaderState();
}

class _TextReaderState extends State<TextReader> {
  static const int range = 4096;

  final ScrollController controller = ScrollController();
  var start = 0;
  var end = range;
  var more = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<RangeData>(
        future: Api().rangeGetStatic(widget.url, start, end),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            mergeContent(snapshot.data);
            return buildContentView();
          } else {
            return buildLoading();
          }
        });
  }

  List<int> content = [];
  String contentText = "";

  Widget buildContentView() {
    return wrap(SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView(
          controller: controller,
          children: [
            SelectableText(contentText),
            if (more)
              TextButton(
                  onPressed: () {
                    setState(() {
                      start = end;
                      end += range;
                    });
                  },
                  child: Text("loadMore"))
          ],
        ),
      ),
    ));
  }

  void mergeContent(RangeData? data) {
    if (data == null || data.content == null || data.contentLength <= 0) {
      more = false;
      return;
    }
    try {
      content.addAll(data.content!);
      contentText = utf8.decode(content);
    } catch (e) {
      print(e);
      contentText = "不支持的类型：${data.contentType}";
      more = false;
    }
    if (data.contentLength < range) {
      more = false;
    }
    if (content.length >= range * 10) {
      more = false;
    }
  }

  Widget buildLoading() {
    return wrap(AppWidgets.pageLoadingView());
  }

  Widget wrap(Widget widget) {
    return Container(
      child: widget,
    );
  }
}
