import 'package:chatapp/utills/colors.dart';
import 'package:flutter/material.dart';

class ChatPersonScreen extends StatefulWidget {
  final String i;
  const ChatPersonScreen({super.key, required this.i});

  @override
  State<ChatPersonScreen> createState() => _ChatPersonScreenState();
}

class _ChatPersonScreenState extends State<ChatPersonScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.lightPink,
        leading: const CircleAvatar(
          backgroundImage: AssetImage(
              'assets/profile_picture.png'), // Replace with the actual image asset or network image
        ),
        title: Text(" ${widget.i}"),
        actions: [
          IconButton(
            icon: Icon(Icons.call),
            onPressed: () {
              // Call action
            },
          ),
          IconButton(
            icon: Icon(Icons.videocam),
            onPressed: () {
              // Video call action
            },
          ),
          IconButton(
            icon: Icon(Icons.more_vert),
            onPressed: () {
              // More options action
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            color: Colors.tealAccent.withOpacity(0.1), // Chat background color
          ),
          Column(
            children: [
              Expanded(
                child: ListView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                  children: [
                    _buildChatBubble("Hello!", true),
                    _buildChatBubble("How are you?", true),
                    _buildChatBubble("I'm fine, thank you.", false),
                    _buildChatBubble("What's up?", true),
                  ],
                ),
              ),
              _buildMessageInput(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(String message, bool isSender) {
    return Align(
      alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
        margin: const EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(
          color: isSender ? AppColors.lightPink : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          message,
          style: TextStyle(
            color: isSender ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.camera_alt),
            onPressed: () {
              // Camera action
            },
          ),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Type a message',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send),
            onPressed: () {
              // Send message action
            },
          ),
        ],
      ),
    );
  }
}
