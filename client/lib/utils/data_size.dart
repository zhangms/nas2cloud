const _k = 1024.0;

String readableDataSize(double size) {
  var value = size / _k;
  if (value < 1) {
    return "<1KB";
  } else if (value < _k) {
    return "${value.toStringAsFixed(2)}KB";
  }
  value = value / _k;
  if (value < _k) {
    return "${value.toStringAsFixed(2)}MB";
  }
  value = (value / _k);
  if (value < _k) {
    return "${value.toStringAsFixed(2)}GB";
  }
  value = (value / _k);
  if (value < _k) {
    return "${value.toStringAsFixed(2)}TB";
  }
  value = (value / _k);
  return "${value.toStringAsFixed(2)}EB";
}
