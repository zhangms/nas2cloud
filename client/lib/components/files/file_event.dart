import '../../dto/file_walk_response.dart';

class FileEvent {
  final FileEventType type;
  final String currentPath;
  final String? source;
  final FileWalkResponseDataFiles? item;

  FileEvent({
    required this.type,
    required this.currentPath,
    this.source,
    this.item,
  });
}

enum FileEventType {
  loaded,
  createFolder,
  orderBy,
  delete,
  toggleFavor,
}
