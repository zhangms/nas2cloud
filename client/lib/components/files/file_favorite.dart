import 'package:flutter/material.dart';
import 'package:nas2cloud/api/dto/file_walk_response/file.dart';
import 'package:nas2cloud/pub/app_nav.dart';
import 'package:nas2cloud/utils/spu.dart';

import '../../api/app_config.dart';
import '../../pub/app_message.dart';

class FileFavorite {
  static AlertDialog buildFavoriteDialog(BuildContext context, File item) {
    var input = TextEditingController();
    input.text = item.name;
    return AlertDialog(
      title: Text("收藏"),
      content: TextField(
        controller: input,
        decoration: InputDecoration(
          labelText: "收藏名称",
        ),
      ),
      actions: [
        TextButton(
            onPressed: (() {
              AppNav.pop(context);
            }),
            child: Text("取消")),
        TextButton(
            onPressed: (() {
              AppNav.pop(context);
              _favorite(context, input.text, item);
            }),
            child: Text("确定"))
      ],
    );
  }

  static Future<void> _favorite(
      BuildContext context, String name, File item) async {
    await add(name, item.path);
    if (context.mounted) {
      AppMessage.show(context, "收藏成功");
    }
  }

  static const String _favoritePrefix = "app.file.favorite.";

  static Future<String?> _favoriteKey() async {
    var userName = await AppConfig.getLoginUserName();
    if (userName == null) {
      return null;
    }
    return "$_favoritePrefix$userName";
  }

  static Future<bool> add(String name, String path) async {
    var key = await _favoriteKey();
    if (key == null) {
      return false;
    }
    var favorList = (await Spu().getStringList(key)) ?? [];
    favorList.removeWhere((element) => element.startsWith("$path:"));
    favorList.add("$path:$name");
    return await Spu().setStringList(key, favorList);
  }

  static Future<bool> isFavorite(String path) async {
    var key = await _favoriteKey();
    if (key == null) {
      return false;
    }
    var favorList = (await Spu().getStringList(key)) ?? [];
    return favorList.indexWhere((element) => element.startsWith("$path:")) >= 0;
  }

  static Future<void> remove(String path) async {
    var key = await _favoriteKey();
    if (key == null) {
      return;
    }
    var favorList = (await Spu().getStringList(key)) ?? [];
    favorList.removeWhere((element) => element.startsWith("$path:"));
    await Spu().setStringList(key, favorList);
  }
}
