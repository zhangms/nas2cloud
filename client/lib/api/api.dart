import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:nas2cloud/api/response/state.dart';
import 'package:nas2cloud/utils/spu.dart';

class ApiBody {
  final int statusCode;
  final bool success;
  final String message;

  ApiBody.success()
      : success = true,
        message = "OK",
        statusCode = 200;

  ApiBody.fail(int code, String errorMsg)
      : success = false,
        message = errorMsg,
        statusCode = code;
}

class _Api {
  const _Api();

  Future<StateResponse> stateByHost(String address) async {
    try {
      var url = Uri.http(address, "api/state");
      Response resp = await http.get(url);
      if (resp.statusCode != 200) {
        return StateResponse.error(
            resp.statusCode, "服务器状态错误:${resp.statusCode}");
      }
      print(resp.body);
      var body = ApiBody<Map>.fromJson(resp.body);
      if (!body.success) {
        return StateResponse.error(500, body.message);
      }
      return StateResponse.success(body.data["userName"]);
    } catch (e) {
      print(e);
      return StateResponse.error(400, "服务器不可用");
    }
  }

  login({required String username, required String password}) async {
    var url = Uri.http(spu.getHostAddress()!, "/api/user/login");
    return await http.get(url);
  }
}

const api = _Api();
