import 'dart:async';
import 'package:chatapp/app_route/route_name.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class GhostChatSplashScreen extends StatefulWidget {
  const GhostChatSplashScreen({super.key});

  @override
  State<GhostChatSplashScreen> createState() => _GhostChatSplashScreenState();
}

class _GhostChatSplashScreenState extends State<GhostChatSplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoScaleAnimation;
  late Animation<Offset> _titleSlideAnimation;
  late Animation<Offset> _subtitleSlideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    // 1. Logo "Flower" animation: Scale from 0 to 1 with elastic effect
    _logoScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
      ),
    );

    // 2. Title animation: From Top-Right to Center
    _titleSlideAnimation = Tween<Offset>(begin: const Offset(2.0, -2.0), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOutBack),
      ),
    );

    // 3. Subtitle animation: From Bottom-Left to Center
    _subtitleSlideAnimation = Tween<Offset>(begin: const Offset(-2.0, 2.0), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOutBack),
      ),
    );

    // 4. Fade animation for text smoothness
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.7, curve: Curves.easeIn),
      ),
    );

    // Start animation and navigate when done
    _controller.forward();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _navigateToNext();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _navigateToNext() async {
    // Check auth status
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      Get.offAllNamed(AppRoutes.home);
    } else {
      Get.offAllNamed(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated Logo (Flower Opening Effect)
                ScaleTransition(
                  scale: _logoScaleAnimation,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: theme.colorScheme.primary, width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 70,
                      backgroundColor: theme.colorScheme.surface,
                      backgroundImage: const AssetImage('assets/image/ghost_chat_logo.png'),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                
                // Animated Title (From Top-Right)
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _titleSlideAnimation,
                    child: Text(
                      "GHOST CHAT",
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                        letterSpacing: 4.0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Animated Subtitle (From Bottom-Left)
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _subtitleSlideAnimation,
                    child: Text(
                      "Elite messaging experience",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
