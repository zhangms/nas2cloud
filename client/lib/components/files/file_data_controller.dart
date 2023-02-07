import 'dart:math';

import 'package:nas2cloud/api/api.dart';
import 'package:nas2cloud/api/dto/file_walk_request.dart';
import 'package:nas2cloud/api/dto/file_walk_response/file.dart';
import 'package:nas2cloud/api/dto/file_walk_response/file_walk_response.dart';
import 'package:nas2cloud/components/files/file_event.dart';
import 'package:nas2cloud/event/bus.dart';

class FileDataController {
  static const int _pageSize = 50;

  final String path;
  final String orderBy;

  FileDataController({required this.path, required this.orderBy});

  bool _initLoading = false;
  bool _loading = false;
  int _total = 0;
  Map<int, File> _dataMap = {};

  bool get initLoading => _initLoading;
  int get total => _total;

  Future<void> initLoad() async {
    _initLoading = true;
    _loading = false;
    _total = 0;
    await _loadMore(0);
  }

  File? get(int index) {
    var ret = _dataMap[index];
    if (ret == null) {
      _tryLoadMore(index);
    }
    return ret;
  }

  void loadIndexPage(int index) {
    _dataMap.clear();
    final int page = index ~/ _pageSize;
    _loadMore(page);
  }

  int _latestPage = -1;

  void _tryLoadMore(final int index) {
    final int page = index ~/ _pageSize;
    _latestPage = page;
    Future.delayed(Duration(milliseconds: 100), () {
      if (page == _latestPage && _dataMap[index] == null) {
        _loadMore(page);
      }
    });
  }

  Future<void> _loadMore(int page) async {
    if (_loading) {
      return;
    }
    _loading = true;
    try {
      var response = await _fetch(page, 0);
      if (!response.success) {
        return;
      }
      var data = response.data!;
      var files = data.files ?? [];
      for (var i = 0; i < files.length; i++) {
        int index = data.currentStart + i;
        _dataMap[index] = files[i];
      }
      _total = data.total;
    } finally {
      _initLoading = false;
      _loading = false;
      eventBus.fire(FileEvent(type: FileEventType.loaded, currentPath: path));
    }
  }

  Future<FileWalkResponse> _fetch(int page, int retry) async {
    var response = await Api().postFileWalk(FileWalkRequest(
        path: path, pageNo: page, pageSize: _pageSize, orderBy: orderBy));
    if (response.message == "RetryLaterAgain") {
      if (retry >= 5) {
        return FileWalkResponse.fromMap({
          "success": true,
        });
      }
      return await Future.delayed(
          Duration(milliseconds: 200), () => _fetch(page, retry + 1));
    }
    if (!response.success) {
      return response;
    }

    return response;
  }

  List<File> getNearestItems(int index) {
    int start = max(index - _pageSize, 0);
    int end = max(index + _pageSize, _total);
    List<File> list = [];
    for (var i = start; i < end; i++) {
      var item = _dataMap[i];
      if (item != null) {
        list.add(item);
      }
    }
    return list;
  }
}
