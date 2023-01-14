import 'dart:convert';

import 'package:nas2cloud/api/api.dart';

class StateResponse extends ApiBody {
  String? userName;

  StateResponse.success(String username)
      : userName = username,
        super.success();

  StateResponse.fail(int code, String errorMsg) : super.fail(code, errorMsg);

  factory StateResponse.fromJson(String body) {
    var map = jsonDecode(body) as Map;
  }

  // factory StateResponse.fromJson(String body) {
  //   return
  // }

  // get isLogin => userName != null;
}
