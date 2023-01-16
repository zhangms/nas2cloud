import 'dart:convert';

class Nav {
  String path;
  String name;

  Nav({required this.path, required this.name});

  @override
  String toString() => 'Nav(path: $path, name: $name)';

  factory Nav.fromMap(Map<String, dynamic> data) => Nav(
        path: data['path'] as String,
        name: data['name'] as String,
      );

  Map<String, dynamic> toMap() => {
        'path': path,
        'name': name,
      };

  /// `dart:convert`
  ///
  /// Parses the string and returns the resulting Json object as [Nav].
  factory Nav.fromJson(String data) {
    return Nav.fromMap(json.decode(data) as Map<String, dynamic>);
  }

  /// `dart:convert`
  ///
  /// Converts [Nav] to a JSON string.
  String toJson() => json.encode(toMap());
}
