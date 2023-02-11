import 'dart:convert';

class File {
  String name;
  String path;
  String type;
  String? thumbnail;
  String? size;
  String? modTime;
  String? ext;
  bool? favor;
  String? favorName;

  File({
    required this.name,
    required this.path,
    required this.type,
    this.thumbnail,
    this.size,
    this.modTime,
    this.ext,
    this.favor,
    this.favorName,
  });

  @override
  String toString() {
    return 'File(name: $name, path: $path, type: $type, thumbnail: $thumbnail, size: $size, modTime: $modTime, ext: $ext, favor: $favor, favorName: $favorName)';
  }

  factory File.fromMap(Map<String, dynamic> data) => File(
        name: data['name'] as String,
        path: data['path'] as String,
        type: data['type'] as String,
        thumbnail: data['thumbnail'] as String?,
        size: data['size'] as String?,
        modTime: data['modTime'] as String?,
        ext: data['ext'] as String?,
        favor: data['favor'] as bool?,
        favorName: data['favorName'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'path': path,
        'type': type,
        'thumbnail': thumbnail,
        'size': size,
        'modTime': modTime,
        'ext': ext,
        'favor': favor,
        'favorName': favorName,
      };

  /// `dart:convert`
  ///
  /// Parses the string and returns the resulting Json object as [File].
  factory File.fromJson(String data) {
    return File.fromMap(json.decode(data) as Map<String, dynamic>);
  }

  /// `dart:convert`
  ///
  /// Converts [File] to a JSON string.
  String toJson() => json.encode(toMap());

  File copyWith({
    String? name,
    String? path,
    String? type,
    String? thumbnail,
    String? size,
    String? modTime,
    String? ext,
    bool? favor,
    String? favorName,
  }) {
    return File(
      name: name ?? this.name,
      path: path ?? this.path,
      type: type ?? this.type,
      thumbnail: thumbnail ?? this.thumbnail,
      size: size ?? this.size,
      modTime: modTime ?? this.modTime,
      ext: ext ?? this.ext,
      favor: favor ?? this.favor,
      favorName: favorName ?? this.favorName,
    );
  }
}
