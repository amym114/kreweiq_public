import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:krewe_iq/components/custom_app_bar.dart';
import 'package:krewe_iq/components/my_button.dart';
import 'package:krewe_iq/components/my_textfield.dart';
import 'package:krewe_iq/extensions/hover_extensions.dart';
import 'package:krewe_iq/services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  final Function()? onTap;
  const RegisterScreen({super.key, required this.onTap});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Text editing controllers
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  // Sign up method
  void signUserUp() async {
    // Show a loading dialog.
    showDialog(
      context: context,
      builder: (context) {
        return const Center(child: CircularProgressIndicator());
      },
    );

    try {
      if (passwordController.text.trim() ==
          confirmPasswordController.text.trim()) {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );
        Navigator.pop(context); // Dismiss the loading dialog.
        // Delay navigation until the next frame.
        Future.delayed(const Duration(milliseconds: 100), () {
          GoRouter.of(context).go('/trivia');
        });
      } else {
        Navigator.pop(context); // Dismiss loading dialog.
        showErrorMessage("Passwords don't match");
        return;
      }
    } on FirebaseAuthException catch (e) {
      Navigator.pop(context); // Dismiss loading dialog.
      invalidCredential(e.message ?? "Error signing up, please try again.");
    }
  }

  void showErrorMessage(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.deepPurple,
          title: Center(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        );
      },
    );
  }

  void invalidCredential(String errorMessage) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.deepPurple,
          title: Center(
            child: Text(
              errorMessage,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
        appBar: CustomAppBar(),
        backgroundColor: const Color.fromRGBO(218, 212, 239, 1),
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
                    Container(
                      width: screenWidth < 600
                          ? screenWidth * 0.95
                          : screenWidth * 0.7, // Responsive width
                      padding: const EdgeInsets.all(20),

                      child: Column(
                        children: [
                          SizedBox(
                              child: Image.asset(
                                  "/images/kiq-vertical-inverted.png",
                                  width: 200)),
                          const SizedBox(height: 50),

                          // Welcome message
                          Text(
                            'Create an Account!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),

                          const SizedBox(height: 25),

                          // Email textfield
                          MyTextField(
                            controller: emailController,
                            hintText: 'Email',
                            obscureText: false,
                          ),

                          const SizedBox(height: 10),

                          // Password textfield
                          MyTextField(
                            controller: passwordController,
                            hintText: 'Password',
                            obscureText: true,
                          ),

                          const SizedBox(height: 10),

                          // Confirm Password textfield
                          MyTextField(
                            controller: confirmPasswordController,
                            hintText: 'Confirm Password',
                            obscureText: true,
                          ),

                          const SizedBox(height: 25),

                          // Sign up button
                          MyButton(
                            text: "Sign Up",
                            onTap: signUserUp,
                          ),

                          const SizedBox(height: 50),

                          // Or sign up with
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 25.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Divider(
                                    thickness: 0.5,
                                    color: Colors.grey[400],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10.0),
                                  child: Text(
                                    'Or sign up with',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                                Expanded(
                                  child: Divider(
                                    thickness: 0.5,
                                    color: Colors.grey[400],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 10),

                          // Google sign-in button
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: () async {
                                  try {
                                    UserCredential userCredential =
                                        await AuthService().signInWithGoogle();
                                    // print(
                                    //     "Google sign in completed: ${userCredential.user}");
                                    if (userCredential.user != null) {
                                      // Wait a moment to let auth state update.
                                      await Future.delayed(
                                          const Duration(milliseconds: 100));
                                      if (mounted) {
                                        GoRouter.of(context).go('/trivia');
                                      }
                                    }
                                  } catch (e) {
                                    // print("Error during Google sign in: $e");
                                  }
                                },
                                child: Image.asset("/images/google_logo.png",
                                    width: 100),
                              ),
                            ],
                          ).showCursorOnHover,

                          const SizedBox(height: 50),

                          // Already have an account? Log in
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Already have an account?',
                                style: TextStyle(color: Colors.white),
                              ),
                              const SizedBox(width: 4),
                              GestureDetector(
                                onTap: () => GoRouter.of(context).go('/login'),
                                child: const Text(
                                  'Log In Now',
                                  style: TextStyle(
                                    color: Color.fromRGBO(244, 184, 96, 1.0),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ));
  }
}
