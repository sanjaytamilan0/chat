import 'package:chatapp/app_route/route_name.dart';
import 'package:chatapp/presentation/auth/riverpod/auth_notifier.dart';
import 'package:chatapp/presentation/call/ui/call_screen.dart';
import 'package:chatapp/presentation/shared/riverpod/theme_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import '../../shared/riverpod/user_data_provider.dart';
import 'edit_profile_screen.dart';
import 'blocked_users_screen.dart';

class SettingScreen extends ConsumerWidget {
  const SettingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserDataStreamProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('User details not found.'));
          }

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 20),
            children: [
              _buildProfileHeader(context, user),
              const SizedBox(height: 32),
              _buildThemeSection(context, ref),
              const SizedBox(height: 32),
              const SettingsList(),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error loading user: $e')),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, dynamic user) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: theme.colorScheme.primary, width: 2),
            ),
            child: CircleAvatar(
              radius: 40,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Icon(Icons.person, color: theme.colorScheme.primary, size: 50),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName ?? 'Unknown Name',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  user.email ?? 'No email associated',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                if (user.bio != null && user.bio!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    user.bio!,
                    style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSection(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final themeNotifier = ref.read(themeProvider.notifier);
    final currentIndex = themeNotifier.currentThemeIndex;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Text(
            'THEME SETTINGS',
            style: theme.textTheme.labelMedium?.copyWith(
              letterSpacing: 1.5,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildThemeCard(context, ref, 0, 'Elite Light', Colors.white, currentIndex == 0),
              _buildThemeCard(context, ref, 1, 'Midnight', const Color(0xFF111827), currentIndex == 1),
              _buildThemeCard(context, ref, 2, 'Royal', const Color(0xFF0F172A), currentIndex == 2),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildThemeCard(BuildContext context, WidgetRef ref, int index, String label, Color color, bool isSelected) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => ref.read(themeProvider.notifier).setTheme(index),
      child: Container(
        width: 120,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : Colors.transparent,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class SettingsList extends ConsumerWidget {
  const SettingsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    return Column(
      children: [
        SettingsItem(
          icon: Icons.edit,
          title: 'Edit Profile',
          onTap: () => Get.to(() => const EditProfileScreen()),
        ),
        SettingsItem(
          icon: Icons.history,
          title: 'Call History',
          onTap: () => Get.to(() => const CallScreen()),
        ),
        SettingsItem(
          icon: Icons.block,
          title: 'Blocked users',
          onTap: () => Get.to(() => const BlockedUsersScreen()),
        ),
        const SettingsItem(
          icon: Icons.delete,
          title: 'Delete account',
        ),
        const SizedBox(height: 16),
        SettingsItem(
          icon: Icons.logout,
          title: 'Logout',
          onTap: () async {
            try {
              await auth.signOut();
              Get.offAllNamed(AppRoutes.login);
            } catch (e) {
              Get.snackbar("Error", "Failed to sign out: $e", snackPosition: SnackPosition.BOTTOM);
            }
          },
          isDestructive: true,
        ),
      ],
    );
  }
}

class SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final bool isDestructive;

  const SettingsItem({
    super.key,
    required this.icon,
    required this.title,
    this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isDestructive ? Colors.red : theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        elevation: 0,
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        child: ListTile(
          leading: Icon(icon, color: color),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: isDestructive ? Colors.red : theme.textTheme.bodyLarge?.color,
            ),
          ),
          trailing: Icon(Icons.arrow_forward_ios, size: 14, color: theme.colorScheme.onSurfaceVariant),
          onTap: onTap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}
