enum FileUploadStatus {
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
}
