import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cha_app/chat_screen.dart';
import 'package:cha_app/login.dart';
import 'package:cha_app/register.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensures proper initialization of async operations before runApp
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? userData = prefs.getString('userData');
  runApp(MyApp(userIsLoggedIn: userData != null));
}

class MyApp extends StatelessWidget {
  final bool userIsLoggedIn;

  const MyApp({super.key, required this.userIsLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: userIsLoggedIn ? '/home' : '/login',
      routes: {
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegistrationScreen(),
        '/home': (context) => ChatScreen(),
      },
    );
  }
}
