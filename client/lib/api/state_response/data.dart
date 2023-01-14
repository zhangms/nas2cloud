import 'dart:convert';

class Data {
  String appName;
  String? userName;

  Data({required this.appName, this.userName});

  @override
  String toString() => 'Data(appName: $appName, userName: $userName)';

  factory Data.fromMap(Map<String, dynamic> data) => Data(
        appName: data['appName'] as String,
        userName: data['userName'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'appName': appName,
        'userName': userName,
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
