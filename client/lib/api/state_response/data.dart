import 'dart:convert';

class Data {
  String appName;
  String? userName;
  String? staticAddress;

  Data({required this.appName, this.userName, this.staticAddress});

  @override
  String toString() {
    return 'Data(appName: $appName, userName: $userName, staticAddress: $staticAddress)';
  }

  factory Data.fromMap(Map<String, dynamic> data) => Data(
        appName: data['appName'] as String,
        userName: data['userName'] as String?,
        staticAddress: data['staticAddress'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'appName': appName,
        'userName': userName,
        'staticAddress': staticAddress,
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
