import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'api_service.dart';

class RegistrationScreen extends StatefulWidget {
  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  final _apiService = ApiService();

  @override
  void dispose() {
    // Dispose controllers when the widget is removed from the widget tree
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      bool isRegistered = await _apiService.register(
          _usernameController.text,
          _emailController.text,
          _passwordController.text
      );
      setState(() => _isLoading = false);

      if (isRegistered) {
        Fluttertoast.showToast(msg: "Registration Successful", toastLength: Toast.LENGTH_SHORT);
        Navigator.of(context).pushReplacementNamed('/login'); // Navigates to home screen after registration
      } else {
        Fluttertoast.showToast(msg: "Registration Failed", toastLength: Toast.LENGTH_SHORT);
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
                Text("Register", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                SizedBox(height: 20),
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(labelText: "Username", border: OutlineInputBorder()),
                  validator: (value) => value!.isEmpty ? "Please enter username" : null,
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(labelText: "Email", border: OutlineInputBorder()),
                  validator: (value) => !value!.contains('@') ? "Please enter a valid email" : null,
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(labelText: "Password", border: OutlineInputBorder()),
                  obscureText: true,
                  validator: (value) => value!.isEmpty ? "Please enter password" : null,
                ),

                SizedBox(height: 30),
                _isLoading
                    ? CircularProgressIndicator()
                    : ElevatedButton(
                  onPressed: _register,
                  child: Text("Register"),
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
