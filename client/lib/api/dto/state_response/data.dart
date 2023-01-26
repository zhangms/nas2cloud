import 'dart:convert';

class Data {
  String appName;
  String publicKey;
  String? userName;
  String? staticAddress;
  String? userAvatar;

  Data({
    required this.appName,
    required this.publicKey,
    this.userName,
    this.staticAddress,
    this.userAvatar,
  });

  @override
  String toString() {
    return 'Data(appName: $appName, publicKey: $publicKey, userName: $userName, staticAddress: $staticAddress, userAvatar: $userAvatar)';
  }

  factory Data.fromMap(Map<String, dynamic> data) => Data(
        appName: data['appName'] as String,
        publicKey: data['publicKey'] as String,
        userName: data['userName'] as String?,
        staticAddress: data['staticAddress'] as String?,
        userAvatar: data['userAvatar'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'appName': appName,
        'publicKey': publicKey,
        'userName': userName,
        'staticAddress': staticAddress,
        'userAvatar': userAvatar,
      };

  /// `dart:convert`
  ///
  /// Parses the string and returns the resulting Json object as [Data].
  factory Data.fromJson(String data) {
    return Data.fromMap(json.decode(data) as Map<String, dynamic>);
  }

  /// `dart:convert`
  ///
  /// Converts [Data] to a JSON string.
  String toJson() => json.encode(toMap());
}
