enum UploadStatus {
  waiting,
  uploading,
  successed,
  failed;

  static bool match(String name, UploadStatus status) {
    return name == status.name;
  }

  static UploadStatus? valueOf(String name) {
    for (var state in UploadStatus.values) {
      if (state.name == name) {
        return state;
      }
    }
    return null;
  }
}
