class AutoUploadDirConfig {
  final String name;
  final String path;
  String? remote;
  bool autoupload;

  AutoUploadDirConfig({
    required this.name,
    required this.path,
    required this.autoupload,
    this.remote,
  });

  AutoUploadDirConfig copyWith({
    String? name,
    String? path,
    String? remote,
    bool? autoupload,
  }) {
    return AutoUploadDirConfig(
      name: name ?? this.name,
      path: path ?? this.path,
      remote: remote ?? this.remote,
      autoupload: autoupload ?? this.autoupload,
    );
  }
}

class AutoUploader {
  static saveAutoUploadConfig(AutoUploadDirConfig config) {}
}
