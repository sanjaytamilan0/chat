import 'package:chatapp/chat_screen/chat_person_screen/chat_person_screen.dart';
import 'package:chatapp/utills/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chatapp/call_screen/call_screen.dart';
import 'package:chatapp/chat_screen/chat_screen.dart';
import 'package:chatapp/reverpod/auth_providers/auth_notifier.dart';

import '../reverpod/auth_providers/user_auth.dart';

final emailMatchProvider = StateNotifierProvider<EmailMatchNotifier, bool>((ref) => EmailMatchNotifier());

class EmailMatchNotifier extends StateNotifier<bool> {
  EmailMatchNotifier() : super(false);
  final authSetting = UserAuth();
  String? userId;

  Future<void> checkEmailMatch(BuildContext context, String enteredEmail) async {
    CollectionReference users = FirebaseFirestore.instance.collection('Users');
    QuerySnapshot querySnapshot = await users.where('email', isEqualTo: enteredEmail).get();

    if (querySnapshot.docs.isNotEmpty) {
      DocumentSnapshot matchedUser = querySnapshot.docs.first;

      // Get the current user's ID (you should have this information from your auth provider)
      final currentUserId = authSetting.auth.currentUser?.uid;

      if (currentUserId != null) {
        // Update state
        state = true;
        userId = matchedUser['id'];

        // Add matched user to the current user's friend list
        await users.doc(currentUserId).update({
          'friendList': FieldValue.arrayUnion([matchedUser.id])
        });

        // Navigate to the chat screen with the matched user
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatPersonScreen(
              chatId: matchedUser['id'],
              otherUserName: matchedUser['name'],
            ),
          ),
        );
      }
    } else {
      state = false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email not found')),
      );
    }
  }
}


class HomeScreen extends ConsumerStatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController emailController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final emailMatches = ref.read(emailMatchProvider);
    final emailMatchNotifier = ref.read(emailMatchProvider.notifier);
    final auth = ref.watch(authProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.lightPink,
          elevation: 0,
          title: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const TextField(
              decoration: InputDecoration(
                hintText: 'Search by name, number...',
                border: InputBorder.none,
                suffixIcon: Icon(Icons.search, color: Colors.teal),
                contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.exit_to_app),
              onPressed: () async {
                try {
                  await auth.signOut();
                  Navigator.of(context).pushReplacementNamed('/login');
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to sign out: $e')),
                  );
                }
              },
            ),
          ],
          bottom: const TabBar(
            indicatorColor: Colors.black,
            labelColor: Colors.black,
            unselectedLabelColor: Colors.white,
            tabs: [
              Tab(text: 'Chats'),
              Tab(text: 'Calls'),
            ],
          ),
        ),
        body: TabBarView(
          children: [ChatScreen(), const CallScreen()],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return


                   AlertDialog(
                      title: const Text('Enter Your Friend\'s Email'),
                      content: TextFormField(
                        controller: emailController,
                        // onChanged: (value) async {
                        //   await emailMatchNotifier.checkEmailMatch(context,value.trim());
                        // },
                        decoration: const InputDecoration(
                          // suffixIcon: emailMatches
                          //     ? const Icon(Icons.circle, color: Colors.green)
                          //     : const Icon(Icons.circle_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () async {
                            final enteredEmail = emailController.text.trim();
                            await emailMatchNotifier.checkEmailMatch(context,enteredEmail);

                          },
                          child: const Text('OK'),
                        ),
                      ],
                    );

              },
            );
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
