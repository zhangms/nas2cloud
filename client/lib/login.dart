import 'package:flutter/material.dart';

import 'layout/adaptive.dart';

class LoginPage extends StatefulWidget {
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  var obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return SafeArea(
        child: Center(
          child: SizedBox(
            width: screenMainAreaWidth(context: context),
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
            style: Theme.of(context).primaryTextTheme.headlineSmall,
          )),
    );
  }

  TextField usernameTextField() {
    return TextField(
      textInputAction: TextInputAction.next,
      cursorColor: Theme.of(context).colorScheme.onSurface,
      decoration: InputDecoration(labelText: "用户名"),
    );
  }

  TextField passwordTextField() {
    return TextField(
      obscureText: obscurePassword,
      textInputAction: TextInputAction.next,
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
