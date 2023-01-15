import 'dart:convert';

class FileWalkReqeust {
  String path;
  int pageNo;
  String orderBy;

  FileWalkReqeust({
    required this.path,
    required this.pageNo,
    required this.orderBy,
  });

  @override
  String toString() {
    return 'FileWalkReqeust(path: $path, pageNo: $pageNo, orderBy: $orderBy)';
  }

  factory FileWalkReqeust.fromMap(Map<String, dynamic> data) {
    return FileWalkReqeust(
      path: data['path'] as String,
      pageNo: data['pageNo'] as int,
      orderBy: data['orderBy'] as String,
    );
  }

  Map<String, dynamic> toMap() => {
        'path': path,
        'pageNo': pageNo,
        'orderBy': orderBy,
      };

  /// `dart:convert`
  ///
  /// Parses the string and returns the resulting Json object as [FileWalkReqeust].
  factory FileWalkReqeust.fromJson(String data) {
    return FileWalkReqeust.fromMap(json.decode(data) as Map<String, dynamic>);
  }

  /// `dart:convert`
  ///
  /// Converts [FileWalkReqeust] to a JSON string.
  String toJson() => json.encode(toMap());
}
