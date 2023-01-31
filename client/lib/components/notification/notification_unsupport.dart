import 'notification.dart';

class UnsupportNotification extends LocalNotification {
  @override
  Future<void> initialize() async {}

  @override
  void send({required int id, required String title, required String body}) {}

  @override
  void progress(
      {required int id,
      required String title,
      required String body,
      required int progress}) {}

  @override
  void clear({required int id}) {}
}
