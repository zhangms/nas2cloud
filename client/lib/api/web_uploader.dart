class _WebUploader {
  addToUpload(
      {required String path,
      required int size,
      required String name,
      Stream<List<int>>? readStream}) {
    if (readStream == null || size <= 0 || path == "/" || path.isEmpty) {
      return;
    }
  }
}

var webUploader = _WebUploader();
