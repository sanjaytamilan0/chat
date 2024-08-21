import 'package:chatapp/splash_screen/splash_screen.dart';
import 'package:flutter/material.dart';

import 'app_route/app_route.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return  const MaterialApp(
      debugShowCheckedModeBanner: false,
      // home: SplashScreenSequence(),
      onGenerateRoute: RouteGenerator.onGeneratedRoute,
      initialRoute: '/',
    );
  }
}
