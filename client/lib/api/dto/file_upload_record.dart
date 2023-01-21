import 'dart:convert';

class FileUploadRecord {
  String id;
  String fileName;
  String filePath;
  int size;
  int beginUploadTime;
  int endUploadTime;
  int fileLastModTime;
  String dest;
  String status;
  int progress;
  String message;

  FileUploadRecord({
    required this.id,
    required this.fileName,
    required this.filePath,
    required this.size,
    required this.beginUploadTime,
    required this.endUploadTime,
    required this.fileLastModTime,
    required this.dest,
    required this.status,
    required this.progress,
    required this.message,
  });

  @override
  String toString() {
    return 'FileUploadRecord(id: $id, fileName: $fileName, filePath: $filePath, size: $size, beginUploadTime: $beginUploadTime, endUploadTime: $endUploadTime, fileLastModTime: $fileLastModTime, dest: $dest, status: $status, progress: $progress, message: $message)';
  }

  factory FileUploadRecord.fromMap(Map<String, dynamic> data) {
    return FileUploadRecord(
      id: data['id'] as String,
      fileName: data['fileName'] as String,
      filePath: data['filePath'] as String,
      size: data['size'] as int,
      beginUploadTime: data['beginUploadTime'] as int,
      endUploadTime: data['endUploadTime'] as int,
      fileLastModTime: data['fileLastModTime'] as int,
      dest: data['dest'] as String,
      status: data['status'] as String,
      progress: data['progress'] as int,
      message: data['message'] as String,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'fileName': fileName,
        'filePath': filePath,
        'size': size,
        'beginUploadTime': beginUploadTime,
        'endUploadTime': endUploadTime,
        'fileLastModTime': fileLastModTime,
        'dest': dest,
        'status': status,
        'progress': progress,
        'message': message,
      };

  /// `dart:convert`
  ///
  /// Parses the string and returns the resulting Json object as [FileUploadRecord].
  factory FileUploadRecord.fromJson(String data) {
    return FileUploadRecord.fromMap(json.decode(data) as Map<String, dynamic>);
  }

  /// `dart:convert`
  ///
  /// Converts [FileUploadRecord] to a JSON string.
  String toJson() => json.encode(toMap());
}
