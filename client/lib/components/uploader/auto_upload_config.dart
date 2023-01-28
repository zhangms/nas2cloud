import 'dart:convert';

class AutoUploadConfig {
  String name;
  String path;
  bool autoupload;
  String? remote;

  AutoUploadConfig({
    required this.name,
    required this.path,
    required this.autoupload,
    this.remote,
  });

  @override
  String toString() {
    return 'AutoUploadDirConfig(name: $name, path: $path, autoupload: $autoupload, remote: $remote)';
  }

  factory AutoUploadConfig.fromMap(Map<String, dynamic> data) {
    return AutoUploadConfig(
      name: data['name'] as String,
      path: data['path'] as String,
      autoupload: data['autoupload'] as bool,
      remote: data['remote'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'path': path,
        'autoupload': autoupload,
        'remote': remote,
      };

  /// `dart:convert`
  ///
  /// Parses the string and returns the resulting Json object as [AutoUploadConfig].
  factory AutoUploadConfig.fromJson(String data) {
    return AutoUploadConfig.fromMap(json.decode(data) as Map<String, dynamic>);
  }

  /// `dart:convert`
  ///
  /// Converts [AutoUploadConfig] to a JSON string.
  String toJson() => json.encode(toMap());

  AutoUploadConfig copyWith({
    String? name,
    String? path,
    bool? autoupload,
    String? remote,
  }) {
    return AutoUploadConfig(
      name: name ?? this.name,
      path: path ?? this.path,
      autoupload: autoupload ?? this.autoupload,
      remote: remote ?? this.remote,
    );
  }
}
