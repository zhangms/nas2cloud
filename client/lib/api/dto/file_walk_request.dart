import 'dart:convert';

class FileWalkRequest {
  String path;
  int pageNo;
  int pageSize;
  String orderBy;

  FileWalkRequest({
    required this.path,
    required this.pageNo,
    required this.pageSize,
    required this.orderBy,
  });

  @override
  String toString() {
    return 'FileWalkRequest(path: $path, pageNo: $pageNo, pageSize: $pageSize, orderBy: $orderBy)';
  }

  factory FileWalkRequest.fromMap(Map<String, dynamic> data) {
    return FileWalkRequest(
      path: data['path'] as String,
      pageNo: data['pageNo'] as int,
      pageSize: data['pageSize'] as int,
      orderBy: data['orderBy'] as String,
    );
  }

  Map<String, dynamic> toMap() => {
        'path': path,
        'pageNo': pageNo,
        'pageSize': pageSize,
        'orderBy': orderBy,
      };

  /// `dart:convert`
  ///
  /// Parses the string and returns the resulting Json object as [FileWalkRequest].
  factory FileWalkRequest.fromJson(String data) {
    return FileWalkRequest.fromMap(json.decode(data) as Map<String, dynamic>);
  }

  /// `dart:convert`
  ///
  /// Converts [FileWalkRequest] to a JSON string.
  String toJson() => json.encode(toMap());
}
