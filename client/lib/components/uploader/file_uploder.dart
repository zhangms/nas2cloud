import 'package:flutter/foundation.dart';
import 'package:nas2cloud/components/uploader/file_upload_record.dart';
import 'package:nas2cloud/components/uploader/file_upload_status_enum.dart';
import 'package:nas2cloud/components/uploader/path_uploader.dart';
import 'package:nas2cloud/components/uploader/web_uploader.dart';

typedef FileUploadListener = void Function(FileUploadRecord record);

abstract class FileUploader {
  static FileUploader? _uploader;

  factory FileUploader.get() {
    if (_uploader != null) {
      return _uploader!;
    }
    if (kIsWeb) {
      _uploader = WebUploader();
    } else {
      _uploader = PathUploader();
    }
    return _uploader!;
  }

  List<FileUploadListener> _listeners = [];

  FileUploader();

  Future<bool> init() async {
    return true;
  }

  Future<bool> uploadStream(
      {required String dest,
      required String fileName,
      required int size,
      required Stream<List<int>> stream});

  int getCount();

  Future<bool> uploadPath({required String src, required String dest});

  FileUploadRecord? getRecord(int index);

  void addListener(FileUploadListener listener) {
    _listeners.add(listener);
    print("file_uploader add listener size: ${_listeners.length}");
  }

  void removeListener(FileUploadListener listener) {
    _listeners.remove(listener);
    print("file_uploader remove listener size: ${_listeners.length}");
  }

  void notifyListeners(FileUploadRecord record) {
    for (var listener in _listeners) {
      listener(record);
    }
  }

  void clearRecordByState(List<FileUploadStatus> filters);
}
