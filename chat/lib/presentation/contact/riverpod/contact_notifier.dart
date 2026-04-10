import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../model/user_model.dart';
import '../../shared/riverpod/user_data_provider.dart';

/// Provides a list of contacts (all users except the current logged-in user)
final contactProvider = StreamProvider<List<UserModel>>((ref) {
  final allUsersAsync = ref.watch(allUsersProvider);
  final currentUserId = FirebaseAuth.instance.currentUser?.uid;

  return allUsersAsync.when(
    data: (users) {
      // Filter out the current user
      final filteredUsers = users.where((user) => user.uid != currentUserId).toList();
      return Stream.value(filteredUsers);
    },
    loading: () => const Stream.empty(),
    error: (err, stack) => Stream.error(err),
  );
});
