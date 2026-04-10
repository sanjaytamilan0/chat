import 'package:chatapp/app_route/route_name.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../utills/colors.dart';
import '../../auth/riverpod/user_auth.dart';

class SplashScreenSequence extends StatefulWidget {
  const SplashScreenSequence({super.key});

  @override
  _SplashScreenSequenceState createState() => _SplashScreenSequenceState();
}

class _SplashScreenSequenceState extends State<SplashScreenSequence> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final auth = UserAuth();

  @override
  void initState() {
    super.initState();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
  }

  void _skip() {
    if (auth.auth.currentUser != null) {
      Get.offAllNamed(AppRoutes.home);
    } else {
      Get.offAllNamed(AppRoutes.login);
    }
  }

  void _nextPage() {
    if (_currentPage < 2) {
      if (auth.auth.currentUser != null) {
        if (_currentPage == 2) {
          Get.offAllNamed(AppRoutes.home);
        }
      } else {
        if (_currentPage == 2) {
          Get.offAllNamed(AppRoutes.login);
          return;
        }
      }

      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );
    } else {
      _skip();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            children: const [
              SplashScreen(
                color: AppColors.lightPink,
                description: 'Welcome to ChatConnect!',
                imageUrl: 'data:image/png;base64,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|',
              ),
              SplashScreen(
                color: AppColors.lightPink,
                description: 'Enjoy end-to-end encrypted chats that keep your conversations safe and private.',
                imageUrl: 'data:image/png;base64,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|',
              ),
              SplashScreen(
                color: AppColors.lightPink,
                description: 'Create group chats with friends, family, or colleagues. Stay in touch and plan together, all in one place.',
                imageUrl: 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAANUAAACUCAMAAAAzmpx4AAAAxlBMVEX///8AAAD///36+vqqqqrt7e2GhoYASF2Li4sQEBDd3d0AR14JCQk4ODh/f38AQFgAOlPX19eenp65ubnz8/NISEgASVuVlZXR0dE9PT1iYmKysrLDw8NqamoAL0sANE0iIiIuLi5ycnJQUFBjeYQAJEQALUTH0NUbQlbR3N85V2h1go+otb6Vo6uRm6JZWVmGkZ1YbHpTY3QKNkkAJT9DYnKGnqfd5+slSVi4xspZbXQoTGMZGRl5i5UeUGJmcn0AFDNMV2nXVlADAAAIC0lEQVR4nO2aC3eiShLHaRrESKQRUXyCGg2oEB/ReN2Yvbvf/0tt9QMkjzuacUfiOf07MyM0zTn9n+qqrmpaUSQSiUQikUgkEolEIpFIJBKJRCKRSCQSiUQikUgkkstR4Y/KL9Tsmj9R//GlH48q/r7TQ+9uWJNQ9VHDTSsSMEm7eDlerdfr1XgZ77LWG0Z1w/HzJCAcg9ibYB66NyuKBQgcJtHENhkGBf5t2ptZUlNucioyUdMl8c0maCH+ZPP46G82AaHaiP/6NL3JoAEjTmYB2Ma0J5vtS7yfTqf7+GU7obYzDHsWFz3C30BVdjNqJ0KitxDnHuBwHBFigvm2u8JG97vgMCImBIdVoiss5olVmIXEZEtnIvkrLHqU3wFGjuMIxh28xrpYhpWjLJXqimyzSaJYuamgkdjEaD6Op8r7UR+vw7UPQSS6Geeixog3BnhOgn+x3LpzGvEn+2sO7TLCR3Cp6JcDpiHy2TCbdngbUxCWqZltGEzUpyQw60SbXyDwk1uJhDC3muZj8uvsnOrFLxtC/Df8D11+FjGsU3ZyTuqAn7b/Wm1r1xjUpegRBIq/XeWmYvYJVGUJIdueivL3VO9byQVdCAHBy5l2opoqtdYfHtKF0EEmtmk8u+e/gMv31T86qIuBQbprYvhJdnvyDQWX0BmqcIGBEmSEr6YZTb8RKc5SpZfL+kUju5An27Dn505AylmqKggVFv/pBJwHTf9bKeu5qiq/PawLAVWVGTFeT6Z2bqVbtrwem1RMldtySmWtkjkPrtR5h5bm0EZQVe52nUKUUbeCzG69+ypOqEdfq43uEaXRxUxVu9Zh98gRzqN7Q3bf7nkICVWU+tWkvGcfGGTM8or87rO4Fj+tKkILz7EG6ACGAFWDNmqUPeuAkMeshUHksKQ5D2jwgO5pC7WVphVjK4XmgAaZp4Jye+w5kXobHbouyHEbqO9SVeheczHGlSEasAW5jNBIp2bUwD6pqsL8CogDw15yDbTO1920wHfTSwVs0+OdMdVAVTn8HsauwU9tiEbCw+pHVUXmwElgkiee3qmK/jQbT/le+26+HfNCSl+gfv4NOgPTtQihEshxhMl45+JVqakqhU2/2CfB2GWGW27IZM761BqpaTj5yN5AFqYTsJ0FQ694VUyISZb8Bqonv2lveUDc2k0yY2ohVnTzL31WVUKN7KlWvCognpgsWrD9sfA1CJ54DNz7dhAzVbX2KVuVfpatgD3YaozTzb/wKXaZk4Gsp5gHkS/86oOqvF91foSqkJh0FVZScynKsXwUwb2MhiIGuvT3syqIgZbIJLvHGFhYEUZLwJlpzsJ3Na6q5C4B/Q5Vuaz+wXK/UKWMYM1lc7B7OKoqX0fDZ2h2O7abzzG/Thdhpiu3ErfuEHpwNOuO5RJfqFLaIAZyiwY6NO6YKpcK7XmLq0sSQNwL5ie+|',
              )
            ],
          ),
          Positioned(
            top: 40,
            right: 20,
            child: Visibility(
              visible: _currentPage < 2,
              child: TextButton(
                onPressed: _skip,
                child: const Text(
                  "Skip",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: _nextPage,
              child: Text(
                _currentPage == 2 ? "Get Started" : "Next",
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SplashScreen extends StatelessWidget {
  final Color color;
  final String? text;
  final String? description;
  final String? imageUrl;

  const SplashScreen({
    super.key,
    required this.color,
    this.text,
    required this.description,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: color,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (imageUrl != null)
              Image.network(
                imageUrl!,
                width: 200,
                height: 200,
              ),
            if (text != null)
              Text(
                text!,
                style: const TextStyle(fontSize: 24, color: Colors.white),
              ),
            if (description != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
                child: Text(
                  description!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
