import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../home/riverpod/email_match_notifier.dart';

class DialogUtils {
  static void showAddFriendDialog(BuildContext context, TextEditingController emailController) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        return Consumer(
          builder: (context, ref, _) {
            final emailMatchState = ref.watch(emailMatchProvider);
            final emailMatchNotifier = ref.read(emailMatchProvider.notifier);

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              backgroundColor: theme.colorScheme.surface,
              title: Text(
                "Add New Friend",
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Enter your friend's email address to start chatting.",
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: emailController,
                    autofocus: true,
                    style: theme.textTheme.bodyLarge,
                    decoration: InputDecoration(
                      hintText: 'email@example.com',
                      prefixIcon: Icon(Icons.email_outlined, color: theme.colorScheme.primary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                    ),
                  ),
                ],
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      onPressed: emailMatchState.isLoading
                          ? null
                          : () async {
                              final enteredEmail = emailController.text.trim();
                              await emailMatchNotifier.checkEmailMatch(context, enteredEmail);
                            },
                      child: emailMatchState.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text(
                              'Add Friend',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
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
