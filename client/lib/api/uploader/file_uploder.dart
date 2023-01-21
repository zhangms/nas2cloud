import 'package:flutter/foundation.dart';
import 'package:nas2cloud/api/dto/file_upload_record.dart';
import 'package:nas2cloud/api/dto/file_upload_status_enum.dart';
import 'package:nas2cloud/api/uploader/unsupport.dart';
import 'package:nas2cloud/api/uploader/web.dart';

typedef FileUploadListener = void Function(FileUploadRecord record);

abstract class FileUploader {
  static FileUploader? _uploader;

  factory FileUploader.getInstance() {
    if (_uploader != null) {
      return _uploader!;
    }
    if (kIsWeb) {
      _uploader = WebUploader();
    } else {
      _uploader = UnsupportUploader();
    }
    return _uploader!;
  }

  List<FileUploadListener> _listeners = [];

  FileUploader();

  Future<bool> fireStreamUploadEvent(
      {required String dest,
      required String fileName,
      required int size,
      required Stream<List<int>> stream});

  int getCount();

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
