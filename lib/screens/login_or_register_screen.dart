import 'package:flutter/material.dart';
import 'package:krewe_iq/screens/login_screen.dart';
import 'package:krewe_iq/screens/register_screen.dart'; 

class LoginOrRegisterScreen extends StatefulWidget {
  const LoginOrRegisterScreen({super.key});

  @override
  State<LoginOrRegisterScreen> createState() => _LoginOrRegisterScreenState();
}

class _LoginOrRegisterScreenState extends State<LoginOrRegisterScreen> {

  // initially show login page 
  bool showLoginPage = true;

  // toggle between login and register page 
  void togglePages() { 
    setState(() {
      showLoginPage = !showLoginPage; 
    });
  }

  @override
  Widget build(BuildContext context) {
    if(showLoginPage) { 
      return LoginScreen(
        onContinueAsGuest: (){},
        onTap: togglePages,
      ); 
    } else { 
      return RegisterScreen(
        onTap: togglePages,
      ); 
    }
  }
}