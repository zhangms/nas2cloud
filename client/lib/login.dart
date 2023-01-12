import 'dart:math';

import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  @override
  State<LoginPage> createState() => _LoginPageState();
}

const _horizontalPadding = 24.0;

double desktopLoginScreenMainAreaWidth({required BuildContext context}) {
  return min(
    360,
    MediaQuery.of(context).size.width - 2 * _horizontalPadding,
  );
}

class _LoginPageState extends State<LoginPage> {
  var obscurePassword = true;
  var eyeColor = Colors.red;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return SafeArea(
        child: Center(
          child: SizedBox(
            width: desktopLoginScreenMainAreaWidth(context: context),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                usernameTextField(),
                passwordTextField(),
                SizedBox(
                  height: 20,
                ),
                loginButton(),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget loginButton() {
    return SizedBox(
      width: 200,
      height: 45,
      child: ElevatedButton(
          style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all(Colors.blue)),
          onPressed: (() {
            print("object");
          }),
          child: Text(
            "登录",
            style: Theme.of(context).primaryTextTheme.headline6,
          )),
    );
  }

  TextField usernameTextField() {
    return TextField(
      textInputAction: TextInputAction.next,
      restorationId: 'username_text_field',
      cursorColor: Theme.of(context).colorScheme.onSurface,
      decoration: InputDecoration(labelText: "用户名"),
    );
  }

  TextField passwordTextField() {
    return TextField(
      obscureText: obscurePassword,
      textInputAction: TextInputAction.next,
      restorationId: 'password_text_field',
      cursorColor: Theme.of(context).colorScheme.onSurface,
      decoration: InputDecoration(
          labelText: "密码",
          suffixIcon: IconButton(
            icon: Icon(
              Icons.remove_red_eye_outlined,
              color: eyeColor,
            ),
            onPressed: () {
              setState(() {
                obscurePassword = !obscurePassword;
                if (obscurePassword) {
                  eyeColor = Colors.red;
                } else {
                  eyeColor = Colors.grey;
                }
              });
            },
          )),
    );
  }
}
