enum FileUploadStatus {
  waiting,
  uploading,
  success,
  error;

  static bool isAny(String stateName, List<FileUploadStatus> status) {
    for (var e in status) {
      if (e.name == stateName) {
        return true;
      }
    }
    return false;
  }

  static FileUploadStatus? valueOf(String stateName) {
    for (var e in FileUploadStatus.values) {
      if (e.name == stateName) {
        return e;
      }
    }
    return null;
  }
}
