import 'package:chatapp/model/status_model.dart';
import 'package:chatapp/presentation/shared/riverpod/user_data_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';

class EditStatusScreen extends ConsumerStatefulWidget {
  const EditStatusScreen({super.key});

  @override
  ConsumerState<EditStatusScreen> createState() => _EditStatusScreenState();
}

class _EditStatusScreenState extends ConsumerState<EditStatusScreen> {
  final List<StatusTextElement> _texts = [];
  int _selectedColorIndex = 0;

  final List<Color> _eliteColors = [
    const Color(0xFF10B981), // Emerald
    const Color(0xFF3B82F6), // Royal Blue
    const Color(0xFF6366F1), // Indigo
    const Color(0xFF8B5CF6), // Violet
    const Color(0xFFEC4899), // Pink
    const Color(0xFFF59E0B), // Amber
    const Color(0xFF111827), // Midnight
    const Color(0xFF1E293B), // Slate
  ];

  void _addText() {
    String newText = "";
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("New Status Text"),
        content: TextField(
          autofocus: true,
          onChanged: (v) => newText = v,
          style: const TextStyle(fontWeight: FontWeight.bold),
          decoration: const InputDecoration(hintText: "Enter text here..."),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if (newText.trim().isNotEmpty) {
                setState(() {
                  _texts.add(StatusTextElement(
                    text: newText.trim(),
                    x: 0.5, // Start at center
                    y: 0.5,
                  ));
                });
                Navigator.pop(context);
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  Future<void> _postStatus() async {
    if (_texts.isEmpty) {
      Get.snackbar("Missing Text", "Please add at least one text item",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
      return;
    }

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    final userData = ref.read(currentUserDataStreamProvider).value;
    final userName = userData?.displayName ?? "User";

    try {
      await FirebaseFirestore.instance.collection('statuses').add({
        'uid': currentUserId,
        'userName': userName,
        'text': _texts.first.text, // Legacy support (using first text)
        'texts': _texts.map((e) => e.toMap()).toList(),
        'color': _eliteColors[_selectedColorIndex].value,
        'createdAt': FieldValue.serverTimestamp(),
      });
      Get.back();
      Get.snackbar("Success", "Status posted!",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white);
    } catch (e) {
      Get.snackbar("Error", "Could not post status: $e",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedColor = _eliteColors[_selectedColorIndex];

    return Scaffold(
      backgroundColor: selectedColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("Create Status",
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
              onPressed: _addText,
              icon: const Icon(Icons.text_fields_rounded, size: 28)),
          TextButton(
            onPressed: _postStatus,
            child: const Text("POST",
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              // Draggable Texts
              ...List.generate(_texts.length, (index) {
                final element = _texts[index];
                return Positioned(
                  left: element.x * constraints.maxWidth - 50,
                  // rough offset adjustment
                  top: element.y * constraints.maxHeight - 20,
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      setState(() {
                        double newX = (element.x * constraints.maxWidth +
                                details.delta.dx) /
                            constraints.maxWidth;
                        double newY = (element.y * constraints.maxHeight +
                                details.delta.dy) /
                            constraints.maxHeight;

                        // Clamp to screen
                        newX = newX.clamp(0.05, 0.95);
                        newY = newY.clamp(0.05, 0.95);

                        _texts[index] = StatusTextElement(
                            text: element.text, x: newX, y: newY);
                      });
                    },
                    onLongPress: () {
                      setState(() {
                        _texts.removeAt(index);
                      });
                      Get.snackbar("Removed", "Text element removed",
                          snackPosition: SnackPosition.BOTTOM,
                          duration: const Duration(seconds: 1));
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        element.text,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              }),

              if (_texts.isEmpty)
                const Center(
                  child: Text(
                    "Tap T at top to add text",
                    style: TextStyle(
                        color: Colors.white54,
                        fontSize: 20,
                        fontWeight: FontWeight.w500),
                  ),
                ),

              // Color Picker
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: SizedBox(
                  height: 60,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _eliteColors.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _selectedColorIndex = index),
                        child: Container(
                          width: 44,
                          height: 44,
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: _eliteColors[index],
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: _selectedColorIndex == index ? 3 : 1,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
