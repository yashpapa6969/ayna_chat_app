import 'dart:convert';
import 'package:cha_app/url.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  Future<bool> login(String username, String password) async {
    var url = Uri.parse('${URL.url}/api/auth/login');
    final response = await http.post(url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"username": username, "password": password}));
    print(response.body);


    if (response.statusCode == 200) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      print(response);
      await prefs.setString('user', response.body); // Assume the whole response is the user data
      return true;
    } else {
      return false;
    }
  }

  Future<bool> register(String username, String email, String password) async {
    var url = Uri.parse('${URL.url}/api/auth/register');
    var body = {
      'username': username,
      'email': email,
      'password': password,
    };
    print(body);
    final response = await http.post(url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(<String, String>{
          'username': username,
          'email': email,
          'password': password,
        }));
    print(response.body);

    if (response.statusCode == 201) {
      return true;
    } else {
      return false;
    }
  }
}
