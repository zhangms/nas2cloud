class PageData<T> {
  final int page;
  final int total;
  final List<T> data;
  PageData(this.page, this.total, this.data);
}
