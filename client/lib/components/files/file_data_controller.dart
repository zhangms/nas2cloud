import 'package:nas2cloud/api/api.dart';
import 'package:nas2cloud/api/dto/file_walk_request.dart';
import 'package:nas2cloud/api/dto/file_walk_response/file.dart';

class FileDataController {
  static const int _pageSize = 50;

  final String path;
  final String orderBy;
  final Function loadEndCallback;

  FileDataController(this.path, this.orderBy, this.loadEndCallback);

  bool initLoading = false;
  bool loading = false;
  int total = 0;
  Map<int, File> dataMap = {};

  Future<void> initLoad() async {
    initLoading = true;
    loading = false;
    total = 0;
    await loadMore(0);
  }

  File? get(int index) {
    var ret = dataMap[index];
    if (ret == null) {
      tryLoadMore(index);
    }
    return ret;
  }

  int pageLatest = -1;

  void tryLoadMore(final int index) {
    final int page = index ~/ _pageSize;
    pageLatest = page;
    Future.delayed(Duration(milliseconds: 100), () {
      if (page == pageLatest && dataMap[index] == null) {
        loadMore(page);
      }
    });
  }

  Future<void> loadMore(int page) async {
    if (loading) {
      return;
    }
    loading = true;
    try {
      var response = await Api().postFileWalk(FileWalkRequest(
          path: path, pageNo: page, pageSize: _pageSize, orderBy: orderBy));
      if (!response.success) {
        return;
      }
      var data = response.data!;
      var files = data.files ?? [];
      for (var i = 0; i < files.length; i++) {
        int index = data.currentStart + i;
        dataMap[index] = files[i];
      }
      total = data.total;
    } finally {
      initLoading = false;
      loading = false;
      loadEndCallback();
    }
  }
}
