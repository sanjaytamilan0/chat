import 'package:flutter/material.dart';
import 'package:chatapp/chat_screen/chat_person_screen/chat_person_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // Sample fake user data
  final List<Map<String, String>> users = [
    {
      "name": "John Doe",
      "lastMessage": "Hey, how are you?",
      "avatarUrl": "https://via.placeholder.com/150"
    },
    {
      "name": "Jane Smith",
      "lastMessage": "Let's catch up later!",
      "avatarUrl": "https://via.placeholder.com/150"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ListView.separated(
            itemBuilder: (_, i) {
              return ListTile(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ChatPersonScreen(i: users[i]['name']!),
                    ),
                  );
                },
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(users[i]["avatarUrl"]!),
                ),
                title: Text(users[i]["name"]!),
                subtitle: Text(users[i]["lastMessage"]!),
              );
            },
            separatorBuilder: (_, i) {
              return const Divider();
            },
            itemCount: users.length,
          ),
        ),
      ],
    );
  }
}
