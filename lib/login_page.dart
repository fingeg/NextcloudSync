import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:nextcloud_sync/keys.dart';
import 'package:nextcloud_sync/static.dart';

// ignore: public_member_api_docs
class _LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<_LoginPage> {
  final FocusNode _passwordFieldFocus = FocusNode();
  final FocusNode _submitButtonFocus = FocusNode();
  final TextEditingController _usernameFieldController =
      TextEditingController();
  final TextEditingController _passwordFieldController =
      TextEditingController();

  bool _checkingLogin = false;

  Future _submitLogin() async {
    try {
      if (_usernameFieldController.text.isEmpty ||
          _passwordFieldController.text.isEmpty) {
        Scaffold.of(context).showSnackBar(SnackBar(
          content: Text('Username und Passwort erforderlich'),
        ));
        return;
      }
      setState(() {
        _checkingLogin = true;
      });
      final dio = Dio()
        ..options = BaseOptions(
          headers: {
            'authorization':
                'Basic ${base64.encode(utf8.encode('${_usernameFieldController.text}:${_passwordFieldController.text}'))}',
          },
          responseType: ResponseType.plain,
          connectTimeout: 3000,
          receiveTimeout: 3000,
        );

      final response = await dio.get(
        'https://ldap.vs-ac.de/login',
      );
      if (json.decode(response.data)['status']) {
        Static.sharedPreferences
            .setString(Keys.username, _usernameFieldController.text);
        Static.sharedPreferences
            .setString(Keys.password, _passwordFieldController.text);
        Navigator.of(context).pushReplacementNamed('/');
      } else {
        _passwordFieldController.text = '';
        Scaffold.of(context).showSnackBar(SnackBar(
          content: Text('Username oder Passwort falsch'),
        ));
      }
      setState(() {
        _checkingLogin = false;
      });
    } on DioError {
      setState(() {
        _checkingLogin = false;
      });
      Scaffold.of(context).showSnackBar(SnackBar(
        content: Text('Fehler beim Anmelden'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final usernameField = TextField(
      obscureText: false,
      enabled: !_checkingLogin,
      decoration: InputDecoration(
        hintText: 'Username',
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: Theme.of(context).accentColor,
            width: 2,
          ),
        ),
      ),
      controller: _usernameFieldController,
      onSubmitted: (_) {
        FocusScope.of(context).requestFocus(_passwordFieldFocus);
      },
    );
    final passwordField = TextField(
      obscureText: true,
      enabled: !_checkingLogin,
      decoration: InputDecoration(
        hintText: 'Passwort',
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: Theme.of(context).accentColor,
            width: 2,
          ),
        ),
      ),
      controller: _passwordFieldController,
      focusNode: _passwordFieldFocus,
      onSubmitted: (_) {
        FocusScope.of(context).requestFocus(_submitButtonFocus);
        _submitLogin();
      },
    );
    final submitButton = Container(
      margin: EdgeInsets.only(top: 10),
      width: double.infinity,
      child: FlatButton(
        focusNode: _submitButtonFocus,
        onPressed: _submitLogin,
        child: _checkingLogin ? CircularProgressIndicator() : Text('Anmelden'),
      ),
    );
    return Center(
      child: Scrollbar(
        child: ListView(
          shrinkWrap: true,
          padding: EdgeInsets.all(10),
          children: [
            usernameField,
            passwordField,
            submitButton,
          ],
        ),
      ),
    );
  }
}

// ignore: public_member_api_docs
class LoginPageWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Scaffold(
        body: _LoginPage(),
      );
}
