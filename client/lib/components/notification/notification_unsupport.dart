import 'notification.dart';

class UnsupportNotification extends LocalNotification {
  @override
  Future<void> initialize() async {}

  @override
  Future<void> send(
      {required int id, required String title, required String body}) async {}

  @override
  Future<void> progress(
      {required int id,
      required String title,
      required String body,
      required int progress}) async {}

  @override
  Future<void> clear({required int id}) async {}
}
