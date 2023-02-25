import 'dart:convert';

class SearchPhotoResponse {
  SearchPhotoResponseData? data;
  String? message;
  bool success;

  SearchPhotoResponse({
    this.data,
    this.message,
    required this.success,
  });

  factory SearchPhotoResponse.fromMap(Map<String, dynamic> data) {
    return SearchPhotoResponse(
      data: data['data']==null ? null : SearchPhotoResponseData.fromMap(data['data'] as Map<String, dynamic>),
      message: data['message'] as String?,
      success: data['success'] as bool,
    );
  }

  Map<String, dynamic> toMap() => {
      'data': data?.toMap(),
      'message': message,
      'success': success,
  };

  factory SearchPhotoResponse.fromJson(String data) {
    return SearchPhotoResponse.fromMap(json.decode(data) as Map<String, dynamic>);
  }

  String toJson() => json.encode(toMap());

  @override
  String toString() => toJson();

  SearchPhotoResponse copyWith({
    SearchPhotoResponseData? data,
    String? message,
    bool? success,
  }) {
    return SearchPhotoResponse(
      data: data ?? this.data,
      message: message ?? this.message,
      success: success ?? this.success,
    );
  }
}

class SearchPhotoResponseData {
  List<SearchPhotoResponseDataFiles>? files;
  String searchAfter;

  SearchPhotoResponseData({
    this.files,
    required this.searchAfter,
  });

  factory SearchPhotoResponseData.fromMap(Map<String, dynamic> data) {
    return SearchPhotoResponseData(
      files: (data['files'] as List<dynamic>?)?.map((e) => SearchPhotoResponseDataFiles.fromMap(e as Map<String, dynamic>)).toList(),
      searchAfter: data['searchAfter'] as String,
    );
  }

  Map<String, dynamic> toMap() => {
      'files': files?.map((e) => e.toMap()).toList(),
      'searchAfter': searchAfter,
  };

  factory SearchPhotoResponseData.fromJson(String data) {
    return SearchPhotoResponseData.fromMap(json.decode(data) as Map<String, dynamic>);
  }

  String toJson() => json.encode(toMap());

  @override
  String toString() => toJson();

  SearchPhotoResponseData copyWith({
    List<SearchPhotoResponseDataFiles>? files,
    String? searchAfter,
  }) {
    return SearchPhotoResponseData(
      files: files ?? this.files,
      searchAfter: searchAfter ?? this.searchAfter,
    );
  }
}

class SearchPhotoResponseDataFiles {
  String? ext;
  bool? favor;
  String? favorName;
  String? modTime;
  String name;
  String path;
  String type;
  String? size;
  String? thumbnail;

  SearchPhotoResponseDataFiles({
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

  factory SearchPhotoResponseDataFiles.fromMap(Map<String, dynamic> data) {
    return SearchPhotoResponseDataFiles(
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

  factory SearchPhotoResponseDataFiles.fromJson(String data) {
    return SearchPhotoResponseDataFiles.fromMap(json.decode(data) as Map<String, dynamic>);
  }

  String toJson() => json.encode(toMap());

  @override
  String toString() => toJson();

  SearchPhotoResponseDataFiles copyWith({
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
    return SearchPhotoResponseDataFiles(
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