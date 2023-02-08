import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../../../utils/file_helper.dart';

class LocalDirListGridView extends StatelessWidget {
  final String dir;
  final int maxCount;

  LocalDirListGridView(this.dir, this.maxCount);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
        future: getLocalFiles(),
        builder: (context, snapshot) {
          if (snapshot.data == null) {
            return Text("");
          }
          return buildFileGrid(snapshot.data!);
        });
  }

  Future<List<String>> getLocalFiles() async {
    Directory directory = Directory(dir);
    try {
      var files = await directory
          .list()
          .map((event) => event.path)
          .where((element) {
            var name = p.basename(element);
            return !name.startsWith(".");
          })
          .take(maxCount)
          .toList();
      return files;
    } catch (e) {
      print(e);
      return [];
    }
  }

  Widget buildFileGrid(List<String> data) {
    return GridView.count(
      crossAxisCount: 4,
      children: [
        for (var path in data) buildFileCard(path),
      ],
    );
  }

  Widget buildFileCard(String path) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SizedBox(
        height: 300,
        width: 300,
        child: FutureBuilder<FileStat>(
            future: fileStat(path),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return buildItemWidget(context, snapshot.data!);
              }
              return Text("");
            }),
      ),
    );
  }

  Future<FileStat> fileStat(String path) async {
    var isDir = await FileSystemEntity.isDirectory(path);
    return FileStat(path: path, isDirectory: isDir);
  }

  Widget buildItemWidget(BuildContext context, FileStat fileStat) {
    if (fileStat.isDirectory) {
      return buildFileCardIcon(context, Icons.folder, fileStat.name);
    }
    if (FileHelper.isImage(fileStat.ext)) {
      return Image.file(File(fileStat.path));
    }
    if (FileHelper.isVideo(fileStat.ext)) {
      return buildFileCardIcon(context, Icons.video_file, fileStat.name);
    }
    return buildFileCardIcon(context, Icons.insert_drive_file, fileStat.name);
  }

  Widget buildFileCardIcon(BuildContext context, IconData icon, String name) {
    return Stack(
      alignment: AlignmentDirectional.bottomCenter,
      children: [
        Icon(
          icon,
          size: 100,
        ),
        Container(
          margin: EdgeInsets.all(8),
          child: Text(
            name,
            style: TextStyle(
                fontSize: 12,
                overflow: TextOverflow.ellipsis,
                color: Theme.of(context).colorScheme.onPrimary),
          ),
        ),
      ],
    );
  }
}

class FileStat {
  String path;
  bool isDirectory;
  String name;
  String ext;

  FileStat({required this.path, required this.isDirectory})
      : name = p.basename(path),
        ext = p.extension(path).toUpperCase();
}
