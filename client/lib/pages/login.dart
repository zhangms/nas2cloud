import 'package:flutter/material.dart';
import 'package:nas2cloud/api/api.dart';
import 'package:nas2cloud/api/app_config.dart';
import 'package:nas2cloud/app.dart';
import 'package:nas2cloud/utils/adaptive.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatefulWidget {
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _loginFormKey = GlobalKey<FormState>();
  var obscurePassword = true;
  var username = TextEditingController();
  var password = TextEditingController();
  var errorMessage = "";
  late AppState appState;

  @override
  Widget build(BuildContext context) {
    appState = context.watch<AppState>();
    return Scaffold(
      appBar: buildAppBar(),
      body: buildBody(),
    );
  }

  LayoutBuilder buildBody() {
    return LayoutBuilder(builder: (context, constraints) {
      return SafeArea(
        child: Center(
          child: SizedBox(
            width: screenMainAreaWidth(context: context),
            child: Form(
              key: _loginFormKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              onChanged: () {
                setErrorMsg("");
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  buildUsernameTextField(),
                  buildPasswordTextField(),
                  SizedBox(
                    height: 20,
                  ),
                  buildLoginButton(),
                  SizedBox(
                    height: 20,
                  ),
                  buildResetHostButton(),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  buildAppBar() {
    return AppBar(
      title: FutureBuilder<String>(
          future: AppConfig.getAppName(),
          builder: (context, snapshot) {
            return Text(snapshot.hasData ? snapshot.data! : "Nas2coud");
          }),
    );
  }

  setErrorMsg(String message) {
    setState(() {
      errorMessage = message;
    });
  }

  login(AppState appState) async {
    setErrorMsg("");
    if (!_loginFormKey.currentState!.validate()) {
      return;
    }
    _loginFormKey.currentState!.save();
    var uname = username.text.trim();
    var pwd = password.text;
    var response = await Api().postLogin(username: uname, password: pwd);
    if (!response.success) {
      setErrorMsg(response.message ?? "Error");
      return;
    }
    await appState.login(response.data!);
  }

  Widget buildLoginButton() {
    var appState = context.watch<AppState>();
    return Column(
      children: [
        Text(errorMessage),
        SizedBox(
          height: 20,
        ),
        SizedBox(
          width: 200,
          height: 45,
          child: ElevatedButton(
              onPressed: (() {
                login(appState);
              }),
              child: Text("登录")),
        ),
      ],
    );
  }

  TextFormField buildUsernameTextField() {
    return TextFormField(
      textInputAction: TextInputAction.next,
      controller: username,
      validator: ((value) {
        if (value!.trim().isEmpty) {
          return "请输入用户名";
        }
        return null;
      }),
      decoration: InputDecoration(labelText: "用户名"),
    );
  }

  TextFormField buildPasswordTextField() {
    return TextFormField(
      obscureText: obscurePassword,
      controller: password,
      textInputAction: TextInputAction.go,
      validator: ((value) {
        if (value!.isEmpty) {
          return "请输入密码";
        }
        return null;
      }),
      decoration: InputDecoration(
          labelText: "密码",
          suffixIcon: IconButton(
            icon: Icon(
              obscurePassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
            ),
            onPressed: () {
              setState(() {
                obscurePassword = !obscurePassword;
              });
            },
          )),
    );
  }

  buildResetHostButton() {
    return TextButton(
        onPressed: (() {
          appState.clearHostAddress();
        }),
        child: Text("重设服务器地址"));
  }
}
