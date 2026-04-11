import 'package:chatapp/presentation/call/ui/call_screen.dart';
import 'package:chatapp/presentation/chat/ui/chat_screen.dart';
import 'package:chatapp/presentation/setting/ui/setting_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../riverpod/email_match_notifier.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;
  final TextEditingController emailController = TextEditingController();

  final List<Widget> _screens = [
    const ChatScreen(),
    const CallScreen(),
    const SettingScreen(),
  ];

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Call History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                _showAddFriendDialog(context);
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  void _showAddFriendDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Consumer(
          builder: (context, ref, _) {
            final emailMatchState = ref.watch(emailMatchProvider);
            final emailMatchNotifier = ref.read(emailMatchProvider.notifier);

            return AlertDialog(
              title: const Text("Enter Your Friend's Email"),
              content: TextFormField(
                controller: emailController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
              ),
              actions: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: const ButtonStyle(
                      backgroundColor: WidgetStatePropertyAll(Colors.red),
                    ),
                    onPressed: emailMatchState.isLoading
                        ? null
                        : () async {
                            final enteredEmail = emailController.text.trim();
                            await emailMatchNotifier.checkEmailMatch(context, enteredEmail);
                          },
                    child: emailMatchState.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'OK',
                            style: TextStyle(color: Colors.white, fontSize: 20),
                          ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
