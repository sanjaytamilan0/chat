
import 'package:chatapp/chat_screen/chat_person_screen/chat_person_screen.dart';
import 'package:flutter/material.dart';

import 'package:chatapp/splash_screen/splash_screen.dart';

import '../bottom_nav_bar.dart';
import '../home_screen/home_screen.dart';
import '../register_screen/login_screen/login_screen.dart';
import '../register_screen/register_screen.dart';

class RouteGenerator {
  static Route<dynamic> onGeneratedRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const SplashScreenSequence());
      case '/login':
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case '/register':
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case '/home':
        return MaterialPageRoute(builder: (_) => const BottomNavBar());

      default:
        return MaterialPageRoute(builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('error'),),
        ));
    }
  }
}
