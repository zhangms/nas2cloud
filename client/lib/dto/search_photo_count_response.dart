import 'dart:convert';

class SearchPhotoCountResponse {
  List<SearchPhotoCountResponseData>? data;
  String? message;
  bool success;

  SearchPhotoCountResponse({
    this.data,
    this.message,
    required this.success,
  });

  factory SearchPhotoCountResponse.fromMap(Map<String, dynamic> data) {
    return SearchPhotoCountResponse(
      data: (data['data'] as List<dynamic>?)?.map((e) => SearchPhotoCountResponseData.fromMap(e as Map<String, dynamic>)).toList(),
      message: data['message'] as String?,
      success: data['success'] as bool,
    );
  }

  Map<String, dynamic> toMap() => {
      'data': data?.map((e) => e.toMap()).toList(),
      'message': message,
      'success': success,
  };

  factory SearchPhotoCountResponse.fromJson(String data) {
    return SearchPhotoCountResponse.fromMap(json.decode(data) as Map<String, dynamic>);
  }

  String toJson() => json.encode(toMap());

  @override
  String toString() => toJson();

  SearchPhotoCountResponse copyWith({
    List<SearchPhotoCountResponseData>? data,
    String? message,
    bool? success,
  }) {
    return SearchPhotoCountResponse(
      data: data ?? this.data,
      message: message ?? this.message,
      success: success ?? this.success,
    );
  }
}

class SearchPhotoCountResponseData {
  String key;
  int value;

  SearchPhotoCountResponseData({
    required this.key,
    required this.value,
  });

  factory SearchPhotoCountResponseData.fromMap(Map<String, dynamic> data) {
    return SearchPhotoCountResponseData(
      key: data['key'] as String,
      value: data['value'] as int,
    );
  }

  Map<String, dynamic> toMap() => {
      'key': key,
      'value': value,
  };

  factory SearchPhotoCountResponseData.fromJson(String data) {
    return SearchPhotoCountResponseData.fromMap(json.decode(data) as Map<String, dynamic>);
  }

  String toJson() => json.encode(toMap());

  @override
  String toString() => toJson();

  SearchPhotoCountResponseData copyWith({
    String? key,
    int? value,
  }) {
    return SearchPhotoCountResponseData(
      key: key ?? this.key,
      value: value ?? this.value,
    );
  }
}