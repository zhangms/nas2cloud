import 'dart:convert';

import 'data.dart';

class LoginResponse {
  bool success;
  String? message;
  Data? data;

  LoginResponse({required this.success, this.message, this.data});

  @override
  String toString() {
    return 'LoginResponse(success: $success, message: $message, data: $data)';
  }

  factory LoginResponse.fromMap(Map<String, dynamic> data) => LoginResponse(
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
  /// Parses the string and returns the resulting Json object as [LoginResponse].
  factory LoginResponse.fromJson(String data) {
    return LoginResponse.fromMap(json.decode(data) as Map<String, dynamic>);
  }

  /// `dart:convert`
  ///
  /// Converts [LoginResponse] to a JSON string.
  String toJson() => json.encode(toMap());
}
