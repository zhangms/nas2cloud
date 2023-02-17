import 'dart:convert';

class FileWalkRequest {
  String orderBy;
  int pageNo;
  int pageSize;
  String path;

  FileWalkRequest({
    required this.orderBy,
    required this.pageNo,
    required this.pageSize,
    required this.path,
  });

  factory FileWalkRequest.fromMap(Map<String, dynamic> data) {
    return FileWalkRequest(
      orderBy: data['orderBy'] as String,
      pageNo: data['pageNo'] as int,
      pageSize: data['pageSize'] as int,
      path: data['path'] as String,
    );
  }

  Map<String, dynamic> toMap() => {
    'orderBy': orderBy,
    'pageNo': pageNo,
    'pageSize': pageSize,
    'path': path,
  };

  factory FileWalkRequest.fromJson(String data) {
    return FileWalkRequest.fromMap(json.decode(data) as Map<String, dynamic>);
  }

  String toJson() => json.encode(toMap());

  @override
  String toString() {return toJson();}

  FileWalkRequest copyWith({
    String? orderBy,
    int? pageNo,
    int? pageSize,
    String? path,
  }) {
    return FileWalkRequest(
      orderBy: orderBy ?? this.orderBy,
      pageNo: pageNo ?? this.pageNo,
      pageSize: pageSize ?? this.pageSize,
      path: path ?? this.path,
    );
  }
}