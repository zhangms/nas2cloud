import 'package:nas2cloud/api/dto/file_walk_response/file.dart';

class FileEvent {
  final FileEventType type;
  final String currentPath;
  final String? source;
  final File? item;

  FileEvent({
    required this.type,
    required this.currentPath,
    this.source,
    this.item,
  });
}

enum FileEventType {
  loaded,
  createFloder,
  orderBy,
  delete,
}
