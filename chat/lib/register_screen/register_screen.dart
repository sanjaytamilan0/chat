
import 'package:chatapp/utills/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chatapp/reverpod/auth_providers/auth_notifier.dart';
import 'package:chatapp/reverpod/auth_providers/user_auth.dart';


class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  final email = FocusNode();
  final password = FocusNode();
  final name = FocusNode();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }


  Future<void> createUserInFirestore(String userId, String email,String name) async {
    final userDoc = FirebaseFirestore.instance.collection('Users').doc(userId);

    await userDoc.set({
      'id':userId,
      'email': email,
      'createdAt': Timestamp.now(),
      'name':name
    });
  }


  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final authNotifier = UserAuth();
    return Scaffold(
      backgroundColor: AppColors.veryLightPink,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.only(left: 5),
                  width: double.maxFinite,
                  decoration: const BoxDecoration(
                      color: AppColors.lightPink,
                      borderRadius: BorderRadius.only(
                          bottomRight: Radius.circular(20),
                          bottomLeft: Radius.circular(20))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                      const Text(
                        "Register",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Fill up your details to register",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                )),
            Expanded(
              flex: 6,
              child: Container(
                padding: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Form(
                  key: _formKey,
                  child: Stack(children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        TextFormField(
                          focusNode: name,
                          onFieldSubmitted: (s) {
                            FocusScope.of(context).requestFocus(email);
                          },
                          controller: _nameController,
                          // keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: 'name',
                            hintText: 'Enter your name',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          focusNode: email,
                          onFieldSubmitted: (s) {
                            FocusScope.of(context).requestFocus(password);
                          },
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            hintText: 'Enter your email',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          focusNode: password,
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            hintText: 'Enter your password',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            suffixIcon: const Icon(Icons.visibility_off),
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
                            onPressed: () async {
                              if (_formKey.currentState?.validate() ?? false) {

                             await auth.signUp(
                                  _emailController.text,
                                  _passwordController.text,
                                ).then((value) {
                                  if(value = true){
                                    final userId = authNotifier.auth.currentUser?.uid ?? '';
                                    final email = _emailController.text;
                                    createUserInFirestore(userId,email,_nameController.text);
                                    Navigator.pushNamed(context, "/login");
                                  }
                                  else{
                                    print(value);
                                  }
                             }

                             );



                              }
                            },

                            child:  const Text(
                              "Register",
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
                        padding: const EdgeInsets.all(20),
                        child: TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, "/login");
                          },
                          child: const Text(
                            "Already have an account? Log in",
                            style: TextStyle(
                              color: AppColors.offWhite,
                            ),
                          ),
                        ),
                      ),
                    )
                  ]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
