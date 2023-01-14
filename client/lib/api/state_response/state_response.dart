import 'dart:convert';

import 'data.dart';

class StateResponse {
  bool success;
  String? message;
  Data? data;

  StateResponse({required this.success, this.message, this.data});

  @override
  String toString() {
    return 'StateResponse(success: $success, message: $message, data: $data)';
  }

  factory StateResponse.fromMap(Map<String, dynamic> data) => StateResponse(
        success: data['success'] as bool,
        message: data['message'] as String?,
        data: data['data'] == null
            ? null
            : Data.fromMap(data['data'] as Map<String, dynamic>),
      );

  Map<String, dynamic> toMap() => {
        'success': success,
        'message': message,
        'data': data?.toMap(),
      };

  /// `dart:convert`
  ///
  /// Parses the string and returns the resulting Json object as [StateResponse].
  factory StateResponse.fromJson(String data) {
    return StateResponse.fromMap(json.decode(data) as Map<String, dynamic>);
  }

  /// `dart:convert`
  ///
  /// Converts [StateResponse] to a JSON string.
  String toJson() => json.encode(toMap());
}
