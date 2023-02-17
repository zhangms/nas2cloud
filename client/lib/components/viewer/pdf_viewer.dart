import 'package:flutter/material.dart';
import 'package:flutter_cached_pdfview/flutter_cached_pdfview.dart';

import '../../pub/widgets.dart';

class PDFViewer extends StatelessWidget {
  final String url;
  final Map<String, String> requestHeader;

  PDFViewer(this.url, this.requestHeader);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: PDF().cachedFromUrl(
          url,
          headers: requestHeader,
          placeholder: (progress) => Center(child: Text("$progress %")),
          errorWidget: (error) => AppWidgets.pageErrorView(error.toString()),
        ),
      ),
    );
  }
}
