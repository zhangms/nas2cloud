class _WebUploader {
  addToUpload(
      {required String dest,
      required int size,
      required String name,
      Stream<List<int>>? readStream}) {
    if (readStream == null || size <= 0 || dest == "/" || dest.isEmpty) {
      return;
    }
  }
}

var webUploader = _WebUploader();
