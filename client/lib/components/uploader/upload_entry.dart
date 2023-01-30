import 'dart:convert';

class UploadEntry {
  int? id;
  String channel;
  String src;
  String dest;
  int size;
  int lastModified;
  int createTime;
  int beginUploadTime;
  int endUploadTime;
  String status;
  String message;

  UploadEntry({
    this.id,
    required this.channel,
    required this.src,
    required this.dest,
    required this.size,
    required this.lastModified,
    required this.createTime,
    required this.beginUploadTime,
    required this.endUploadTime,
    required this.status,
    required this.message,
  });

  @override
  String toString() {
    return 'UploadEntry(id: $id, channel: $channel, src: $src, dest: $dest, size: $size, lastModified: $lastModified, createTime: $createTime, beginUploadTime: $beginUploadTime, endUploadTime: $endUploadTime, status: $status, message: $message)';
  }

  factory UploadEntry.fromMap(Map<String, dynamic> data) => UploadEntry(
        id: data['id'] as int?,
        channel: data['channel'] as String,
        src: data['src'] as String,
        dest: data['dest'] as String,
        size: data['size'] as int,
        lastModified: data['lastModified'] as int,
        createTime: data['createTime'] as int,
        beginUploadTime: data['beginUploadTime'] as int,
        endUploadTime: data['endUploadTime'] as int,
        status: data['status'] as String,
        message: data['message'] as String,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'channel': channel,
        'src': src,
        'dest': dest,
        'size': size,
        'lastModified': lastModified,
        'createTime': createTime,
        'beginUploadTime': beginUploadTime,
        'endUploadTime': endUploadTime,
        'status': status,
        'message': message,
      };

  /// `dart:convert`
  ///
  /// Parses the string and returns the resulting Json object as [UploadEntry].
  factory UploadEntry.fromJson(String data) {
    return UploadEntry.fromMap(json.decode(data) as Map<String, dynamic>);
  }

  /// `dart:convert`
  ///
  /// Converts [UploadEntry] to a JSON string.
  String toJson() => json.encode(toMap());

  UploadEntry copyWith({
    int? id,
    String? channel,
    String? src,
    String? dest,
    int? size,
    int? lastModified,
    int? createTime,
    int? beginUploadTime,
    int? endUploadTime,
    String? status,
    String? message,
  }) {
    return UploadEntry(
      id: id ?? this.id,
      channel: channel ?? this.channel,
      src: src ?? this.src,
      dest: dest ?? this.dest,
      size: size ?? this.size,
      lastModified: lastModified ?? this.lastModified,
      createTime: createTime ?? this.createTime,
      beginUploadTime: beginUploadTime ?? this.beginUploadTime,
      endUploadTime: endUploadTime ?? this.endUploadTime,
      status: status ?? this.status,
      message: message ?? this.message,
    );
  }
}
