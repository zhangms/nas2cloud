import 'dart:convert';

class AutoUploadConfig {
  bool autoupload;
  String basepath;
  String name;
  String path;
  String? remote;

  AutoUploadConfig({
    required this.autoupload,
    required this.basepath,
    required this.name,
    required this.path,
    this.remote,
  });

  factory AutoUploadConfig.fromMap(Map<String, dynamic> data) {
    return AutoUploadConfig(
      autoupload: data['autoupload'] as bool,
      basepath: data['basepath'] as String,
      name: data['name'] as String,
      path: data['path'] as String,
      remote: data['remote'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'autoupload': autoupload,
    'basepath': basepath,
    'name': name,
    'path': path,
    'remote': remote,
  };

  factory AutoUploadConfig.fromJson(String data) {
    return AutoUploadConfig.fromMap(json.decode(data) as Map<String, dynamic>);
  }

  String toJson() => json.encode(toMap());

  @override
  String toString() {return toJson();}

  AutoUploadConfig copyWith({
    bool? autoupload,
    String? basepath,
    String? name,
    String? path,
    String? remote,
  }) {
    return AutoUploadConfig(
      autoupload: autoupload ?? this.autoupload,
      basepath: basepath ?? this.basepath,
      name: name ?? this.name,
      path: path ?? this.path,
      remote: remote ?? this.remote,
    );
  }

  String get uploadChannel => "$path:$remote";
}