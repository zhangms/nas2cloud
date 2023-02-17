import 'dart:convert';

class StateResponse {
  StateResponseData? data;
  String? message;
  bool success;

  StateResponse({
    this.data,
    this.message,
    required this.success,
  });

  factory StateResponse.fromMap(Map<String, dynamic> data) {
    return StateResponse(
      data: data['data']==null ? null : StateResponseData.fromMap(data['data'] as Map<String, dynamic>),
      message: data['message'] as String?,
      success: data['success'] as bool,
    );
  }

  Map<String, dynamic> toMap() => {
      'data': data?.toMap(),
      'message': message,
      'success': success,
  };

  factory StateResponse.fromJson(String data) {
    return StateResponse.fromMap(json.decode(data) as Map<String, dynamic>);
  }

  String toJson() => json.encode(toMap());

  @override
  String toString() => toJson();

  StateResponse copyWith({
    StateResponseData? data,
    String? message,
    bool? success,
  }) {
    return StateResponse(
      data: data ?? this.data,
      message: message ?? this.message,
      success: success ?? this.success,
    );
  }
}

class StateResponseData {
  String appName;
  String publicKey;
  String? staticAddress;
  String? userAvatar;
  String? userAvatarLarge;
  String? userName;

  StateResponseData({
    required this.appName,
    required this.publicKey,
    this.staticAddress,
    this.userAvatar,
    this.userAvatarLarge,
    this.userName,
  });

  factory StateResponseData.fromMap(Map<String, dynamic> data) {
    return StateResponseData(
      appName: data['appName'] as String,
      publicKey: data['publicKey'] as String,
      staticAddress: data['staticAddress'] as String?,
      userAvatar: data['userAvatar'] as String?,
      userAvatarLarge: data['userAvatarLarge'] as String?,
      userName: data['userName'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
      'appName': appName,
      'publicKey': publicKey,
      'staticAddress': staticAddress,
      'userAvatar': userAvatar,
      'userAvatarLarge': userAvatarLarge,
      'userName': userName,
  };

  factory StateResponseData.fromJson(String data) {
    return StateResponseData.fromMap(json.decode(data) as Map<String, dynamic>);
  }

  String toJson() => json.encode(toMap());

  @override
  String toString() => toJson();

  StateResponseData copyWith({
    String? appName,
    String? publicKey,
    String? staticAddress,
    String? userAvatar,
    String? userAvatarLarge,
    String? userName,
  }) {
    return StateResponseData(
      appName: appName ?? this.appName,
      publicKey: publicKey ?? this.publicKey,
      staticAddress: staticAddress ?? this.staticAddress,
      userAvatar: userAvatar ?? this.userAvatar,
      userAvatarLarge: userAvatarLarge ?? this.userAvatarLarge,
      userName: userName ?? this.userName,
    );
  }
}