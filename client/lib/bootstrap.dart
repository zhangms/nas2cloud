import 'package:flutter/cupertino.dart';
import 'package:nas2cloud/components/downloader.dart';
import 'package:nas2cloud/components/notification/notification.dart';
import 'package:nas2cloud/components/uploader/file_uploder.dart';
import 'package:nas2cloud/utils/spu.dart';

initBeforeRunApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  await spu.initSharedPreferences();
  await Downloader.get().init();
  await FileUploader.get().init();
  await LocalNotification.get().init();
}
