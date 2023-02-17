import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_file_view/flutter_file_view.dart';

class DocViewer extends StatefulWidget {
  final String url;
  final Map<String, String> headers;

  DocViewer(this.url, this.headers);

  @override
  State<DocViewer> createState() => _DocViewerState();
}

class _DocViewerState extends State<DocViewer> {
  late FileViewController controller;

  @override
  void initState() {
    super.initState();
    FlutterFileView.init();
    controller = FileViewController.network(
      widget.url,
      androidViewConfig: AndroidViewConfig(
          isBarShow: true, isBarAnimating: true, intoDownloading: true),
      config: NetworkConfig(options: Options(headers: widget.headers)),
      isDelExist: false,
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: FileView(controller: controller)),
    );
  }
}
