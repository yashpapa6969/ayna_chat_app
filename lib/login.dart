import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'api_service.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String _username = '';
  String _password = '';
  bool _isLoading = false;
  final _apiService = ApiService();

  void _login() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _isLoading = true);

      bool isLoggedIn = await _apiService.login(_username, _password);
      setState(() => _isLoading = false);

      if (isLoggedIn) {
        Fluttertoast.showToast(msg: "Login Successful", toastLength: Toast.LENGTH_SHORT);
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        Fluttertoast.showToast(msg: "Login Failed", toastLength: Toast.LENGTH_SHORT);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Login", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                SizedBox(height: 20),
                TextFormField(
                  decoration: InputDecoration(labelText: "Username", border: OutlineInputBorder()),
                  validator: (value) => value!.isEmpty ? "Please enter username" : null,
                  onSaved: (value) => _username = value!,
                ),
                SizedBox(height: 20),
                TextFormField(
                  decoration: InputDecoration(labelText: "Password", border: OutlineInputBorder()),
                  obscureText: true,
                  validator: (value) => value!.isEmpty ? "Please enter password" : null,
                  onSaved: (value) => _password = value!,
                ),
                SizedBox(height: 30),
                _isLoading
                    ? CircularProgressIndicator()
                    : ElevatedButton(
                  onPressed: _login,
                  child: Text("Login"),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50),
                  ),
                ),
                SizedBox(height: 20,),
                ElevatedButton(
                  onPressed:(){
                    Navigator.of(context).pushReplacementNamed('/register'); // Navigates to home screen after registration
                  },
                  child: Text("Not yet registered"),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
