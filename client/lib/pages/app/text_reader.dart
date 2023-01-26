import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:nas2cloud/api/api.dart';

class TextReader extends StatefulWidget {
  final String path;

  const TextReader({super.key, required this.path});

  @override
  State<TextReader> createState() => _TextReaderState();
}

class _TextReaderState extends State<TextReader> {
  static const int range = 1024;

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
        future: Api.rangeGetStatic(widget.path, start, end),
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
    var contentType = data.contentType.toLowerCase();
    if (!contentType.startsWith("text") || !contentType.contains("utf-8")) {
      more = false;
      contentText = "不支持的类型：$contentType";
      return;
    }
    try {
      content.addAll(data.content!);
      contentText = utf8.decode(content);
    } catch (e) {
      print(e);
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
    return wrap(Center(
      child: CircularProgressIndicator(),
    ));
  }

  Widget wrap(Widget widget) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: widget,
    );
  }
}
