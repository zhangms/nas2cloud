import 'dart:convert';

class Result {
  bool success;
  String? message;
  String? data;

  Result({required this.success, this.message, this.data});

  @override
  String toString() {
    return 'Result(success: $success, message: $message, data: $data)';
  }

  factory Result.fromMap(Map<String, dynamic> data) => Result(
        success: data['success'] as bool,
        message: data['message'] as String?,
        data: data['data'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'success': success,
        'message': message,
        'data': data,
      };

  /// `dart:convert`
  ///
  /// Parses the string and returns the resulting Json object as [Result].
  factory Result.fromJson(String data) {
    return Result.fromMap(json.decode(data) as Map<String, dynamic>);
  }

  /// `dart:convert`
  ///
  /// Converts [Result] to a JSON string.
  String toJson() => json.encode(toMap());
}
