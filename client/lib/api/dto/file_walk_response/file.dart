import 'dart:convert';

class File {
  String name;
  String path;
  String type;
  String? thumbnail;
  String? size;
  String? modTime;
  String? ext;

  File({
    required this.name,
    required this.path,
    required this.type,
    this.thumbnail,
    this.size,
    this.modTime,
    this.ext,
  });

  @override
  String toString() {
    return 'File(name: $name, path: $path, type: $type, thumbnail: $thumbnail, size: $size, modTime: $modTime, ext: $ext)';
  }

  factory File.fromMap(Map<String, dynamic> data) => File(
        name: data['name'] as String,
        path: data['path'] as String,
        type: data['type'] as String,
        thumbnail: data['thumbnail'] as String?,
        size: data['size'] as String?,
        modTime: data['modTime'] as String?,
        ext: data['ext'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'path': path,
        'type': type,
        'thumbnail': thumbnail,
        'size': size,
        'modTime': modTime,
        'ext': ext,
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
}
