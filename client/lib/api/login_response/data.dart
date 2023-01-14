import 'dart:convert';

class Data {
  String username;
  String token;
  String createTime;

  Data({
    required this.username,
    required this.token,
    required this.createTime,
  });

  @override
  String toString() {
    return 'Data(username: $username, token: $token, createTime: $createTime)';
  }

  factory Data.fromMap(Map<String, dynamic> data) => Data(
        username: data['username'] as String,
        token: data['token'] as String,
        createTime: data['createTime'] as String,
      );

  Map<String, dynamic> toMap() => {
        'username': username,
        'token': token,
        'createTime': createTime,
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
