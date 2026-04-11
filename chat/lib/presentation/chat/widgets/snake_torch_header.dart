import 'dart:math' as math;
import 'package:flutter/material.dart';

class SnakeTorchHeader extends StatefulWidget {
  const SnakeTorchHeader({super.key});

  @override
  State<SnakeTorchHeader> createState() => _SnakeTorchHeaderState();
}

class _SnakeTorchHeaderState extends State<SnakeTorchHeader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const String text = "GHOST CHAT";
    final List<String> characters = text.split('');

    return Container(
      height: 70,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.9), // Dark room effect
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return ShaderMask(
              blendMode: BlendMode.dstIn,
              shaderCallback: (bounds) {
                // Torch/Spotlight movement: Figure-eight path
                double t = _controller.value * 2 * math.pi;
                double xOffset = math.sin(t) * 1.2; // Horizontal scan
                double yOffset = math.cos(t * 2) * 0.3; // Slight vertical jitter
                
                return RadialGradient(
                  center: Alignment(xOffset, yOffset),
                  radius: 0.8,
                  colors: [
                    Colors.white.withOpacity(1.0), // Center of torch
                    Colors.white.withOpacity(0.3), // Halo
                    Colors.transparent, // Darkness
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ).createShader(bounds);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(characters.length, (index) {
                    final char = characters[index];
                    if (char == ' ') return const SizedBox(width: 8);

                    // Snake-like wave parameters
                    final double phase = (_controller.value * 2 * math.pi) - (index * 0.6);
                    final double dy = math.sin(phase) * 12; // Vertical slither
                    final double dx = math.cos(phase) * 6;  // Horizontal slither
                    final double rotation = math.sin(phase) * 0.15; // Slithering rotation

                    return Transform.translate(
                      offset: Offset(dx, dy),
                      child: Transform.rotate(
                        angle: rotation,
                        child: Text(
                          char,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white, // Text shines under torch
                            letterSpacing: 3,
                            shadows: [
                              Shadow(
                                color: theme.colorScheme.primary.withOpacity(0.5),
                                blurRadius: 10,
                                offset: const Offset(0, 0),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
