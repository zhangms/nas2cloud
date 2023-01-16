import 'dart:convert';

import 'file.dart';
import 'nav.dart';

class Data {
  int currentStart;
  int currentStop;
  int currentPage;
  String currentPath;
  int total;
  List<Nav>? nav;
  List<File>? files;

  Data({
    required this.currentStart,
    required this.currentStop,
    required this.currentPage,
    required this.currentPath,
    required this.total,
    this.nav,
    this.files,
  });

  @override
  String toString() {
    return 'Data(currentStart: $currentStart, currentStop: $currentStop, currentPage: $currentPage, currentPath: $currentPath, total: $total, nav: $nav, files: $files)';
  }

  factory Data.fromMap(Map<String, dynamic> data) => Data(
        currentStart: data['currentStart'] as int,
        currentStop: data['currentStop'] as int,
        currentPage: data['currentPage'] as int,
        currentPath: data['currentPath'] as String,
        total: data['total'] as int,
        nav: (data['nav'] as List<dynamic>?)
            ?.map((e) => Nav.fromMap(e as Map<String, dynamic>))
            .toList(),
        files: (data['files'] as List<dynamic>?)
            ?.map((e) => File.fromMap(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toMap() => {
        'currentStart': currentStart,
        'currentStop': currentStop,
        'currentPage': currentPage,
        'currentPath': currentPath,
        'total': total,
        'nav': nav?.map((e) => e.toMap()).toList(),
        'files': files?.map((e) => e.toMap()).toList(),
      };

  /// `dart:convert`
  ///
  /// Parses the string and returns the resulting Json object as [Data].
  factory Data.fromJson(String data) {
    return Data.fromMap(json.decode(data) as Map<String, dynamic>);
  }

  /// `dart:convert`
  ///
  /// Converts [Data] to a JSON string.
  String toJson() => json.encode(toMap());
}
