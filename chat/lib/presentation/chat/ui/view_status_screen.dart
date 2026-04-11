import 'package:chatapp/model/status_model.dart';
import 'package:flutter/material.dart';

class ViewStatusScreen extends StatefulWidget {
  final List<StatusModel> statuses;
  const ViewStatusScreen({super.key, required this.statuses});

  @override
  _ViewStatusScreenState createState() => _ViewStatusScreenState();
}

class _ViewStatusScreenState extends State<ViewStatusScreen> with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(vsync: this);
    
    // Initial status load
    _loadStatus(index: 0);

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _nextStatus();
      }
    });
  }

  void _loadStatus({required int index}) {
    _animationController.stop();
    _animationController.reset();
    _animationController.duration = const Duration(seconds: 5);
    _animationController.forward();
  }

  void _nextStatus() {
    if (_currentIndex < widget.statuses.length - 1) {
      setState(() {
        _currentIndex++;
      });
      _pageController.animateToPage(
        _currentIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _loadStatus(index: _currentIndex);
    } else {
      Navigator.pop(context); // Close on last story completion
    }
  }

  void _previousStatus() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
      _pageController.animateToPage(
        _currentIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _loadStatus(index: _currentIndex);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.statuses.isEmpty) return const Scaffold();

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onLongPressStart: (_) => _animationController.stop(),
        onLongPressEnd: (_) => _animationController.forward(),
        child: Stack(
          children: [
            // Sequential Story View
            PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(), // Disable manual swipe to sync with timer
              itemCount: widget.statuses.length,
              itemBuilder: (context, index) {
                final status = widget.statuses[index];
                final statusColor = Color(status.color);
                
                return LayoutBuilder(
                  builder: (context, constraints) {
                    return Container(
                      color: statusColor,
                      child: Stack(
                        children: [
                          // Legacy support for single text statuses
                          if (status.texts.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 40),
                                child: SelectableText(
                                  status.text,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 34,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                          
                          // Multi-text elements
                          ...status.texts.map((element) {
                            return Positioned(
                              left: (element.x * constraints.maxWidth) - 60, // approximate centering offset
                              top: (element.y * constraints.maxHeight) - 20,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  element.text,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    shadows: [
                                      Shadow(color: Colors.black26, offset: Offset(2, 2), blurRadius: 4)
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    );
                  }
                );
              },
            ),

            // Tap regions for navigation
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _previousStatus,
                    child: Container(color: Colors.transparent),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: _nextStatus,
                    child: Container(color: Colors.transparent),
                  ),
                ),
              ],
            ),

            // Header & Progress Indicators
            SafeArea(
              child: Column(
                children: [
                  // Story Progress Indicator bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      children: List.generate(widget.statuses.length, (index) {
                        return Expanded(
                          child: Stack(
                            children: [
                              Container(
                                height: 3,
                                margin: const EdgeInsets.symmetric(horizontal: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white24,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              if (index <= _currentIndex)
                                AnimatedBuilder(
                                  animation: _animationController,
                                  builder: (context, child) {
                                    final progress = (index < _currentIndex) 
                                        ? 1.0 
                                        : (index == _currentIndex ? _animationController.value : 0.0);
                                    return FractionallySizedBox(
                                      widthFactor: progress,
                                      child: Container(
                                        height: 3,
                                        margin: const EdgeInsets.symmetric(horizontal: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),

                  // User Info Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white, size: 28),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 8),
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          child: Text(
                            _getInitials(widget.statuses.first.userName),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.statuses.first.userName,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              "Status ${_currentIndex + 1} of ${widget.statuses.length}",
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return "?";
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}
