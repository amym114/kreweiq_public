import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:krewe_iq/components/custom_app_bar.dart';
import 'package:krewe_iq/components/my_button.dart';
import 'package:krewe_iq/components/my_textfield.dart';
import 'package:krewe_iq/extensions/hover_extensions.dart';
import 'package:krewe_iq/services/auth_service.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginScreen extends StatefulWidget {
  final Function()? onTap;
  final Function()? onContinueAsGuest; // ✅ Added guest mode function

  const LoginScreen(
      {super.key, required this.onTap, required this.onContinueAsGuest});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  void signUserIn() async {
    showDialog(
      context: context,
      builder: (context) {
        return const Center(child: CircularProgressIndicator());
      },
    );

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );
      Navigator.pop(context);
      GoRouter.of(context).go('/'); // ✅ Redirects to Home after login
    } on FirebaseAuthException catch (e) {
      Navigator.pop(context);
      invalidCredential();
    }
  }

  void invalidCredential() {
    showDialog(
      context: context,
      builder: (context) {
        return const AlertDialog(
          title: Text('Error logging in, please try again.'),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: const CustomAppBar(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF9D00CC), Color(0xFF4A148C)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                      child: Image.asset("/images/kiq-vertical-inverted.png",
                          width: 200)),
                  Container(
                    width: screenWidth < 600
                        ? screenWidth * 0.95
                        : screenWidth * 0.7,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Container(
                          color: Color.fromRGBO(255, 255, 255, .2),
                          padding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 5),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'New here?',
                                style: TextStyle(color: Colors.white),
                              ),
                              SizedBox(
                                  height:
                                      4), // Adds spacing between the two rows
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  TextButton(
                                    onPressed:
                                        widget.onTap, // ✅ Navigates to Register
                                    child: const Text(
                                      'Register now',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color:
                                            Color.fromRGBO(244, 184, 96, 1.0),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    "or",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  TextButton(
                                    onPressed: widget
                                        .onContinueAsGuest, // ✅ Navigates to Guest Mode
                                    child: const Text(
                                      "Continue as Guest",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color:
                                            Color.fromRGBO(244, 184, 96, 1.0),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 25),
                        Text(
                          'Sign In',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        const SizedBox(height: 10),
                        // 📧 Email textfield
                        MyTextField(
                          controller: emailController,
                          hintText: 'Email',
                          obscureText: false,
                        ),

                        const SizedBox(height: 10),

                        // 🔒 Password textfield
                        MyTextField(
                          controller: passwordController,
                          hintText: 'Password',
                          obscureText: true,
                        ),

                        const SizedBox(height: 10),

                        // 🔑 Forgot password?
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 25.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                'Forgot Password?',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 25),

                        // 🟡 Sign in button
                        MyButton(text: "Sign In", onTap: signUserIn),

                        const SizedBox(height: 20),

                        // const SizedBox(height: 50),

                        // ➖ Divider
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 25.0),
                          child: Row(
                            children: [
                              Expanded(
                                child:
                                    Divider(thickness: 1, color: Colors.white),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10.0),
                                child: Text(
                                  'Or sign in with',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                              Expanded(
                                child:
                                    Divider(thickness: 1, color: Colors.white),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 5),

                        // 🌍 Google sign-in button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () async {
                                final userCredential =
                                    await AuthService().signInWithGoogle();
                                if (userCredential != null) {
                                  GoRouter.of(context).go(
                                      '/'); // Redirects to home after Google sign-in
                                }
                              },
                              child: Image.asset("/images/google_logo.png",
                                  width: 100),
                            ),
                          ],
                        ).showCursorOnHover,

                        const SizedBox(height: 50),

                        // 🆕 Not a member? Register now
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
