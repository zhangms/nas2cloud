import 'dart:convert';

class Result {
  String? message;
  bool success;

  Result({
    this.message,
    required this.success,
  });

  factory Result.fromMap(Map<String, dynamic> data) {
    return Result(
      message: data['message'] as String?,
      success: data['success'] as bool,
    );
  }

  Map<String, dynamic> toMap() => {
    'message': message,
    'success': success,
  };

  factory Result.fromJson(String data) {
    return Result.fromMap(json.decode(data) as Map<String, dynamic>);
  }

  String toJson() => json.encode(toMap());

  @override
  String toString() {return toJson();}

  Result copyWith({
    String? message,
    bool? success,
  }) {
    return Result(
      message: message ?? this.message,
      success: success ?? this.success,
    );
  }
}