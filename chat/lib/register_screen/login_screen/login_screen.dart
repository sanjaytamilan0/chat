
import 'package:chatapp/utills/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../reverpod/auth_providers/auth_notifier.dart';
import '../../reverpod/auth_providers/user_auth.dart';

class LoginScreen extends ConsumerStatefulWidget {

  const LoginScreen({super.key,});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final passwordController = TextEditingController();
  final emailController = TextEditingController();
  final auth = UserAuth();

  @override
  void dispose() {
    passwordController.dispose();
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    return WillPopScope(
      onWillPop: () async {
        return Future.value(false);
      },
      child: Scaffold(
        backgroundColor: AppColors.palePink,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.only(left: 20),
                  width: double.maxFinite,
                  // alignment: Alignment.topLeft,
                  decoration: const BoxDecoration(
                      color: AppColors.lightPink,
                      borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(30),
                          bottomRight: Radius.circular(30))),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // IconButton(
                      //   icon: const Icon(Icons.arrow_back),
                      //   onPressed: () {
                      //     Navigator.pop(context);
                      //   },
                      // ),
                      SizedBox(height: 3),
                      Text(
                        "Login",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Enter your 10-digit mobile number to continue",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 8,
                child: Container(
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    // color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Stack(children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextFormField(
                          // inputFormatters: [
                          //   FilteringTextInputFormatter
                          //       .digitsOnly, //Allow only digits
                          //   LengthLimitingTextInputFormatter(10),
                          // ],
                          controller: emailController,
                          // keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: 'email',
                            hintText: 'Enter your mail',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20,),
                        TextFormField(
                          // inputFormatters: [
                          //   FilteringTextInputFormatter
                          //       .digitsOnly, //Allow only digits
                          //   LengthLimitingTextInputFormatter(10),
                          // ],
                          controller: passwordController,
                          // keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            hintText: 'Enter your Password',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.all(16.0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              backgroundColor: AppColors.lightPink,
                            ),
                            onPressed: () {
                              auth.signIn(emailController.text, passwordController.text).then((value) {
                                if(value = true){

                                  Navigator.pushNamedAndRemoveUntil(context, "/home",
                                        (Route<dynamic> route) => false,
                                  );
                                }else{
                                  print(value);
                                }
                              });
                            },
                            child: const Text(
                              "Login",
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        margin: const EdgeInsets.only(left: 20, right: 20),
                        child: TextButton(
                          onPressed: () {

                            Navigator.pushNamed(context, "/register");
                          },
                          child: const Text(
                            "Don’t have an account? Register",
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    )
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
