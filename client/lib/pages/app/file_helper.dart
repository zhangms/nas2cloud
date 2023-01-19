class _FileHelper {
  bool isImageFile(String? ext) {
    if (ext == null) {
      return false;
    }
    switch (ext) {
      case ".JPG":
      case ".JPEG":
      case ".PNG":
        return true;
      default:
        return false;
    }
  }

  bool isVideoFile(String? ext) {
    if (ext == null) {
      return false;
    }
    switch (ext) {
      case ".MP4":
      case ".MOV":
        return true;
      default:
        return false;
    }
  }
}

var fileHelper = _FileHelper();
