import 'dart:convert';

class Data {
  String? userName;

  Data({this.userName});

  @override
  String toString() => 'Data(userName: $userName)';

  factory Data.fromMap(Map<String, dynamic> data) => Data(
        userName: data['userName'] as String?,
      );

  Map<String, dynamic> toMap() => {
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
