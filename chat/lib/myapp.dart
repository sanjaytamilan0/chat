
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'app_route/app_route.dart';
import 'app_route/route_name.dart';
import 'presentation/call/ui/call_attend_screen.dart';
import 'presentation/shared/riverpod/user_data_provider.dart';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    // Global listener for OneSignal login
    ref.watch(oneSignalLoginProvider);

    // Global listener for incoming calls
    ref.listen(incomingCallProvider, (previous, next) {
      next.when(
        data: (snapshot) {
          debugPrint("Global Call Listener: Docs count = ${snapshot.docs.length}");
          
          if (snapshot.docs.isNotEmpty) {
            final callDoc = snapshot.docs.first;
            final callingData = callDoc['callingData'] as Map<String, dynamic>;
            final callerId = callingData['callerId'];
            final callerName = callingData['callerName'];
            final isCalling = callingData['calling'] ?? false;
            final chatId = callDoc.id;

            debugPrint("Global: Call State - calling: $isCalling, caller: $callerName");

            if (callerId != currentUserId && isCalling && Get.isDialogOpen == false) {
              _showGlobalIncomingCallDialog(context, callerName, chatId);
            } else if (!isCalling && Get.isDialogOpen == true) {
              debugPrint("Global: Call ended by signaling. Closing dialog.");
              Get.back();
            }
          } else {
            if (Get.isDialogOpen == true) {
              debugPrint("Global: Call document removed. Closing dialog.");
              Get.back();
            }
          }
        },
        loading: () => debugPrint("Global Call Listener: Loading..."),
        error: (err, stack) => debugPrint("Global Call Listener Error: $err"),
      );
    });

    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      getPages: AppPages.pages,
      initialRoute: AppRoutes.root,
    );
  }

  void _showGlobalIncomingCallDialog(BuildContext context, String callerName, String chatId) {
    Get.dialog(
      AlertDialog(
        title: const Text('Incoming Video Call'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.video_call, size: 64, color: Colors.teal),
            const SizedBox(height: 16),
            Text('$callerName is calling you...', style: const TextStyle(fontSize: 18)),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Decline', style: TextStyle(color: Colors.red)),
            onPressed: () async {
              await FirebaseFirestore.instance.collection('chats').doc(chatId).update({
                'callingData.calling': false,
              });
              Get.back();
            },
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            child: const Text('Accept', style: TextStyle(color: Colors.white)),
            onPressed: () {
              Get.back();
              // Pass the callerName to the VideoCallPage
              Get.to(() => VideoCallPage(channelId: chatId, remoteName: callerName));
            },
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }
}
