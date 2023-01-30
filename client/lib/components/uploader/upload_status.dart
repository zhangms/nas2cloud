enum UploadStatus {
  waiting,
  uploading,
  successed,
  failed;

  static bool match(String name, UploadStatus status) {
    return name == status.name;
  }
}
