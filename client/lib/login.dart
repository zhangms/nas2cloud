import 'package:flutter/material.dart';
import 'package:nas2cloud/api/api.dart';
import 'package:nas2cloud/app.dart';
import 'package:provider/provider.dart';

import 'layout/adaptive.dart';

class LoginPage extends StatefulWidget {
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  var obscurePassword = true;
  final _loginFormKey = GlobalKey<FormState>();
  var username = TextEditingController();
  var password = TextEditingController();
  var errorMessage = "";

  @override
  Widget build(BuildContext context) {
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
                  textFieldUsername(),
                  textFieldPassword(),
                  SizedBox(
                    height: 20,
                  ),
                  buttonLogin(),
                ],
              ),
            ),
          ),
        ),
      );
    });
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
    var response = await api.login(username: uname, password: pwd);
    if (!response.success) {
      setErrorMsg(response.message ?? "Error");
      return;
    }
    appState.onLoginSuccess(response.data!);
  }

  Widget buttonLogin() {
    var appState = context.watch<AppState>();
    return Column(
      children: [
        Text(
          errorMessage,
          style: TextStyle(
            color: Colors.red,
          ),
        ),
        SizedBox(
          height: 20,
        ),
        SizedBox(
          width: 200,
          height: 45,
          child: ElevatedButton(
              style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(Colors.blue)),
              onPressed: (() {
                login(appState);
              }),
              child: Text(
                "登录",
                style: Theme.of(context).primaryTextTheme.headlineSmall,
              )),
        ),
      ],
    );
  }

  TextFormField textFieldUsername() {
    return TextFormField(
      textInputAction: TextInputAction.next,
      controller: username,
      validator: ((value) {
        if (value!.trim().isEmpty) {
          return "请输入用户名";
        }
      }),
      cursorColor: Theme.of(context).colorScheme.onSurface,
      decoration: InputDecoration(labelText: "用户名"),
    );
  }

  TextFormField textFieldPassword() {
    return TextFormField(
      obscureText: obscurePassword,
      controller: password,
      textInputAction: TextInputAction.go,
      validator: ((value) {
        if (value!.isEmpty) {
          return "请输入密码";
        }
      }),
      cursorColor: Theme.of(context).colorScheme.onSurface,
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
}
