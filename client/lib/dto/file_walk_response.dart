import 'dart:convert';

class FileWalkResponse {
  FileWalkResponseData? data;
  String? message;
  bool success;

  FileWalkResponse({
    this.data,
    this.message,
    required this.success,
  });

  factory FileWalkResponse.fromMap(Map<String, dynamic> data) {
    return FileWalkResponse(
      data: data['data']==null ? null : FileWalkResponseData.fromMap(data['data'] as Map<String, dynamic>),
      message: data['message'] as String?,
      success: data['success'] as bool,
    );
  }

  Map<String, dynamic> toMap() => {
    'data': data?.toMap(),
    'message': message,
    'success': success,
  };

  factory FileWalkResponse.fromJson(String data) {
    return FileWalkResponse.fromMap(json.decode(data) as Map<String, dynamic>);
  }

  String toJson() => json.encode(toMap());

  @override
  String toString() {return toJson();}

  FileWalkResponse copyWith({
    FileWalkResponseData? data,
    String? message,
    bool? success,
  }) {
    return FileWalkResponse(
      data: data ?? this.data,
      message: message ?? this.message,
      success: success ?? this.success,
    );
  }
}

class FileWalkResponseData {
  List<FileWalkResponseDataFiles>? files;
  List<FileWalkResponseDataNav>? nav;
  int currentPage;
  String currentPath;
  int currentStart;
  int currentStop;
  int total;

  FileWalkResponseData({
    this.files,
    this.nav,
    required this.currentPage,
    required this.currentPath,
    required this.currentStart,
    required this.currentStop,
    required this.total,
  });

  factory FileWalkResponseData.fromMap(Map<String, dynamic> data) {
    return FileWalkResponseData(
      files: (data['files'] as List<dynamic>?)?.map((e) => FileWalkResponseDataFiles.fromMap(e as Map<String, dynamic>)).toList(),
      nav: (data['nav'] as List<dynamic>?)?.map((e) => FileWalkResponseDataNav.fromMap(e as Map<String, dynamic>)).toList(),
      currentPage: data['currentPage'] as int,
      currentPath: data['currentPath'] as String,
      currentStart: data['currentStart'] as int,
      currentStop: data['currentStop'] as int,
      total: data['total'] as int,
    );
  }

  Map<String, dynamic> toMap() => {
    'files': files?.map((e) => e.toMap()).toList(),
    'nav': nav?.map((e) => e.toMap()).toList(),
    'currentPage': currentPage,
    'currentPath': currentPath,
    'currentStart': currentStart,
    'currentStop': currentStop,
    'total': total,
  };

  factory FileWalkResponseData.fromJson(String data) {
    return FileWalkResponseData.fromMap(json.decode(data) as Map<String, dynamic>);
  }

  String toJson() => json.encode(toMap());

  @override
  String toString() {return toJson();}

  FileWalkResponseData copyWith({
    List<FileWalkResponseDataFiles>? files,
    List<FileWalkResponseDataNav>? nav,
    int? currentPage,
    String? currentPath,
    int? currentStart,
    int? currentStop,
    int? total,
  }) {
    return FileWalkResponseData(
      files: files ?? this.files,
      nav: nav ?? this.nav,
      currentPage: currentPage ?? this.currentPage,
      currentPath: currentPath ?? this.currentPath,
      currentStart: currentStart ?? this.currentStart,
      currentStop: currentStop ?? this.currentStop,
      total: total ?? this.total,
    );
  }
}

class FileWalkResponseDataFiles {
  String? ext;
  bool? favor;
  String? favorName;
  String? modTime;
  String name;
  String path;
  String type;
  String? size;
  String? thumbnail;

  FileWalkResponseDataFiles({
    this.ext,
    this.favor,
    this.favorName,
    this.modTime,
    required this.name,
    required this.path,
    required this.type,
    this.size,
    this.thumbnail,
  });

  factory FileWalkResponseDataFiles.fromMap(Map<String, dynamic> data) {
    return FileWalkResponseDataFiles(
      ext: data['ext'] as String?,
      favor: data['favor'] as bool?,
      favorName: data['favorName'] as String?,
      modTime: data['modTime'] as String?,
      name: data['name'] as String,
      path: data['path'] as String,
      type: data['type'] as String,
      size: data['size'] as String?,
      thumbnail: data['thumbnail'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'ext': ext,
    'favor': favor,
    'favorName': favorName,
    'modTime': modTime,
    'name': name,
    'path': path,
    'type': type,
    'size': size,
    'thumbnail': thumbnail,
  };

  factory FileWalkResponseDataFiles.fromJson(String data) {
    return FileWalkResponseDataFiles.fromMap(json.decode(data) as Map<String, dynamic>);
  }

  String toJson() => json.encode(toMap());

  @override
  String toString() {return toJson();}

  FileWalkResponseDataFiles copyWith({
    String? ext,
    bool? favor,
    String? favorName,
    String? modTime,
    String? name,
    String? path,
    String? type,
    String? size,
    String? thumbnail,
  }) {
    return FileWalkResponseDataFiles(
      ext: ext ?? this.ext,
      favor: favor ?? this.favor,
      favorName: favorName ?? this.favorName,
      modTime: modTime ?? this.modTime,
      name: name ?? this.name,
      path: path ?? this.path,
      type: type ?? this.type,
      size: size ?? this.size,
      thumbnail: thumbnail ?? this.thumbnail,
    );
  }
}

class FileWalkResponseDataNav {
  String name;
  String path;

  FileWalkResponseDataNav({
    required this.name,
    required this.path,
  });

  factory FileWalkResponseDataNav.fromMap(Map<String, dynamic> data) {
    return FileWalkResponseDataNav(
      name: data['name'] as String,
      path: data['path'] as String,
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'path': path,
  };

  factory FileWalkResponseDataNav.fromJson(String data) {
    return FileWalkResponseDataNav.fromMap(json.decode(data) as Map<String, dynamic>);
  }

  String toJson() => json.encode(toMap());

  @override
  String toString() {return toJson();}

  FileWalkResponseDataNav copyWith({
    String? name,
    String? path,
  }) {
    return FileWalkResponseDataNav(
      name: name ?? this.name,
      path: path ?? this.path,
    );
  }
}