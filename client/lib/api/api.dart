import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:nas2cloud/api/login_response/login_response.dart';
import 'package:nas2cloud/api/state_response/state_response.dart';
import 'package:nas2cloud/utils/spu.dart';

const _exception = {"success": false, "message": "服务器不可用"};

const _loginHttpHeaders = {
  "X-DEVICE": "web",
  "Content-Type": "application/json"
};

class _Api {
  const _Api();

  Future<StateResponse> stateByHost(String address) async {
    try {
      var url = Uri.http(address, "api/state");
      Response resp = await http.get(url);
      return StateResponse.fromJson(resp.body);
    } catch (e) {
      print(e);
      return StateResponse.fromMap(_exception);
    }
  }

  Future<LoginResponse> login(
      {required String username, required String password}) async {
    try {
      var url = Uri.http(spu.getHostAddress()!, "/api/user/login");
      Response resp = await http.post(url,
          headers: _loginHttpHeaders,
          body: jsonEncode({
            "username": username,
            "password": password,
          }));
      return LoginResponse.fromJson(resp.body);
    } catch (e) {
      print(e);
      return LoginResponse.fromMap(_exception);
    }
  }
}

const api = _Api();
