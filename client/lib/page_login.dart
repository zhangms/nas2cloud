import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool obscurePwd = true;

  @override
  Widget build(BuildContext context) {
    var pwdEyeColor =
        obscurePwd ? Theme.of(context).iconTheme.color : Colors.grey;

    return Form(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(children: [
          Text(
            "Login",
            style: TextStyle(fontSize: 42),
          ),
          TextFormField(
            decoration: const InputDecoration(labelText: "用户名"),
          ),
          TextFormField(
            obscureText: obscurePwd,
            decoration: InputDecoration(
                labelText: "密码",
                suffixIcon: IconButton(
                  icon: Icon(
                    Icons.remove_red_eye_outlined,
                    color: pwdEyeColor,
                  ),
                  onPressed: () {
                    setState(() {
                      obscurePwd = !obscurePwd;
                    });
                  },
                )),
          ),
          SizedBox(
            height: 32,
          ),
          SizedBox(
            width: 256,
            height: 45,
            child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                ),
                onPressed: (() {
                  print("object");
                }),
                child: Text(
                  "登录",
                  style: Theme.of(context).primaryTextTheme.headline6,
                )),
          )
        ]),
      ),
    );
  }
}
