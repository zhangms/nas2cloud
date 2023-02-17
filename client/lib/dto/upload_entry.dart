import 'dart:convert';

class UploadEntry {
  int? id;
  int beginUploadTime;
  String channel;
  int createTime;
  String dest;
  int endUploadTime;
  int lastModified;
  String message;
  int size;
  String src;
  String status;
  String uploadTaskId;

  UploadEntry({
    this.id,
    required this.beginUploadTime,
    required this.channel,
    required this.createTime,
    required this.dest,
    required this.endUploadTime,
    required this.lastModified,
    required this.message,
    required this.size,
    required this.src,
    required this.status,
    required this.uploadTaskId,
  });

  factory UploadEntry.fromMap(Map<String, dynamic> data) {
    return UploadEntry(
      id: data['id'] as int?,
      beginUploadTime: data['beginUploadTime'] as int,
      channel: data['channel'] as String,
      createTime: data['createTime'] as int,
      dest: data['dest'] as String,
      endUploadTime: data['endUploadTime'] as int,
      lastModified: data['lastModified'] as int,
      message: data['message'] as String,
      size: data['size'] as int,
      src: data['src'] as String,
      status: data['status'] as String,
      uploadTaskId: data['uploadTaskId'] as String,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'beginUploadTime': beginUploadTime,
    'channel': channel,
    'createTime': createTime,
    'dest': dest,
    'endUploadTime': endUploadTime,
    'lastModified': lastModified,
    'message': message,
    'size': size,
    'src': src,
    'status': status,
    'uploadTaskId': uploadTaskId,
  };

  factory UploadEntry.fromJson(String data) {
    return UploadEntry.fromMap(json.decode(data) as Map<String, dynamic>);
  }

  String toJson() => json.encode(toMap());

  @override
  String toString() {return toJson();}

  UploadEntry copyWith({
    int? id,
    int? beginUploadTime,
    String? channel,
    int? createTime,
    String? dest,
    int? endUploadTime,
    int? lastModified,
    String? message,
    int? size,
    String? src,
    String? status,
    String? uploadTaskId,
  }) {
    return UploadEntry(
      id: id ?? this.id,
      beginUploadTime: beginUploadTime ?? this.beginUploadTime,
      channel: channel ?? this.channel,
      createTime: createTime ?? this.createTime,
      dest: dest ?? this.dest,
      endUploadTime: endUploadTime ?? this.endUploadTime,
      lastModified: lastModified ?? this.lastModified,
      message: message ?? this.message,
      size: size ?? this.size,
      src: src ?? this.src,
      status: status ?? this.status,
      uploadTaskId: uploadTaskId ?? this.uploadTaskId,
    );
  }
}