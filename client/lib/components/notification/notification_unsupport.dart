import 'notification.dart';

class UnsupportNotification extends LocalNotification {
  @override
  void initialize() {}

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
