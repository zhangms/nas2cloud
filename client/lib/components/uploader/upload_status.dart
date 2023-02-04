enum UploadStatus {
  //groupIndex 从上到下不能变
  waiting(1),
  uploading(2),
  successed(3),
  failed(3);

  final int groupIndex;
  const UploadStatus(this.groupIndex);

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
