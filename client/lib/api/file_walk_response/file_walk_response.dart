import 'dart:convert';

import 'data.dart';

class FileWalkResponse {
  bool success;
  String? message;
  Data? data;

  FileWalkResponse({required this.success, this.message, this.data});

  @override
  String toString() {
    return 'FileWalkResponse(success: $success, message: $message, data: $data)';
  }

  factory FileWalkResponse.fromMap(Map<String, dynamic> data) {
    return FileWalkResponse(
      success: data['success'] as bool,
      message: data['message'] as String?,
      data: data['data'] == null
          ? null
          : Data.fromMap(data['data'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toMap() => {
        'success': success,
        'message': message,
        'data': data?.toMap(),
      };

  /// `dart:convert`
  ///
  /// Parses the string and returns the resulting Json object as [FileWalkResponse].
  factory FileWalkResponse.fromJson(String data) {
    return FileWalkResponse.fromMap(json.decode(data) as Map<String, dynamic>);
  }

  /// `dart:convert`
  ///
  /// Converts [FileWalkResponse] to a JSON string.
  String toJson() => json.encode(toMap());
}
