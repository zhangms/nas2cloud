class FileHelper {
  static bool isImage(String? ext) {
    switch (ext) {
      case ".JPG":
      case ".JPEG":
      case ".PNG":
        return true;
      default:
        return false;
    }
  }

  static bool isMusic(String? ext) {
    switch (ext) {
      case ".MP3":
      case ".WAV":
        return true;
      default:
        return false;
    }
  }

  static bool isVideo(String? ext) {
    switch (ext) {
      case ".MP4":
      case ".MOV":
      case ".MKV":
        return true;
      default:
        return false;
    }
  }

  static bool isPDF(String? ext) {
    return ext == ".PDF";
  }

  static bool isText(String? ext) {
    switch (ext) {
      case ".TXT":
      case ".TEXT":
      case ".JAVA":
      case ".H":
      case ".CPP":
      case ".PY":
      case ".GO":
      case ".DART":
      case ".JS":
      case ".CSS":
      case ".HTML":
      case ".CONF":
      case ".SH":
      case ".JSON":
      case ".XML":
      case ".LOG":
      case ".SQL":
      case ".PROPERTIES":
      case ".JSP":
      case ".C":
      case ".PHP":
      case ".MD":
        return true;
      default:
        return false;
    }
  }

  static bool isHidden(String filepath) {
    return filepath.indexOf("/.") > 0;
  }
}
