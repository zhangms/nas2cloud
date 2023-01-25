import 'package:flutter/material.dart';
import 'package:flutter_cached_pdfview/flutter_cached_pdfview.dart';
import 'package:nas2cloud/api/api.dart';

class PDFViewer extends StatelessWidget {
  final String url;

  PDFViewer(this.url);

  @override
  Widget build(BuildContext context) {
    return PDF().cachedFromUrl(
      url,
      headers: Api.httpHeaders(),
      placeholder: (progress) => Center(
          child: Text(
        '$progress %',
        style: TextStyle(color: Colors.orange),
      )),
      errorWidget: (error) => Center(child: Text(error.toString())),
    );
  }
}
