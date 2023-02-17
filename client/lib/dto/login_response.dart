import 'dart:convert';

class LoginResponse {
  LoginResponseData? data;
  String? message;
  bool success;

  LoginResponse({
    this.data,
    this.message,
    required this.success,
  });

  factory LoginResponse.fromMap(Map<String, dynamic> data) {
    return LoginResponse(
      data: data['data']==null ? null : LoginResponseData.fromMap(data['data'] as Map<String, dynamic>),
      message: data['message'] as String?,
      success: data['success'] as bool,
    );
  }

  Map<String, dynamic> toMap() => {
    'data': data?.toMap(),
    'message': message,
    'success': success,
  };

  factory LoginResponse.fromJson(String data) {
    return LoginResponse.fromMap(json.decode(data) as Map<String, dynamic>);
  }

  String toJson() => json.encode(toMap());

  @override
  String toString() {return toJson();}

  LoginResponse copyWith({
    LoginResponseData? data,
    String? message,
    bool? success,
  }) {
    return LoginResponse(
      data: data ?? this.data,
      message: message ?? this.message,
      success: success ?? this.success,
    );
  }
}

class LoginResponseData {
  String createTime;
  String token;
  String username;

  LoginResponseData({
    required this.createTime,
    required this.token,
    required this.username,
  });

  factory LoginResponseData.fromMap(Map<String, dynamic> data) {
    return LoginResponseData(
      createTime: data['createTime'] as String,
      token: data['token'] as String,
      username: data['username'] as String,
    );
  }

  Map<String, dynamic> toMap() => {
    'createTime': createTime,
    'token': token,
    'username': username,
  };

  factory LoginResponseData.fromJson(String data) {
    return LoginResponseData.fromMap(json.decode(data) as Map<String, dynamic>);
  }

  String toJson() => json.encode(toMap());

  @override
  String toString() {return toJson();}

  LoginResponseData copyWith({
    String? createTime,
    String? token,
    String? username,
  }) {
    return LoginResponseData(
      createTime: createTime ?? this.createTime,
      token: token ?? this.token,
      username: username ?? this.username,
    );
  }
}