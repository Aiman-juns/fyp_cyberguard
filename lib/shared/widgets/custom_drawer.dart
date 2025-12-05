import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/theme_provider.dart';

class CustomDrawer extends ConsumerWidget {
  const CustomDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return Drawer(
      child: Column(
        children: [
          // Profile Header
          authState.when(
            data: (user) {
              final isDarkMode =
                  Theme.of(context).brightness == Brightness.dark;
              return UserAccountsDrawerHeader(
                accountName: Text(
                  user?.fullName ?? 'User',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                accountEmail: Text(
                  user?.email ?? '',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                currentAccountPicture: CircleAvatar(
                  backgroundImage: NetworkImage(
                    user?.avatarUrl ??
                        'https://api.dicebear.com/7.x/avataaars/svg?seed=default',
                  ),
                  onBackgroundImageError: (exception, stackTrace) {
                    // Fallback if image fails to load
                  },
                ),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Theme.of(context).primaryColor
                      : Colors.blue.shade700,
                ),
              );
            },
            loading: () => const UserAccountsDrawerHeader(
              accountName: Text('Loading...'),
              accountEmail: Text(''),
              currentAccountPicture: CircleAvatar(
                child: CircularProgressIndicator(),
              ),
              decoration: BoxDecoration(color: Colors.blueAccent),
            ),
            error: (error, stackTrace) => const UserAccountsDrawerHeader(
              accountName: Text('Error'),
              accountEmail: Text(''),
              currentAccountPicture: CircleAvatar(child: Icon(Icons.error)),
              decoration: BoxDecoration(color: Colors.redAccent),
            ),
          ),
          // Menu Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('Profile Settings'),
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Navigate to profile settings
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Profile Settings - Coming Soon'),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.info),
                  title: const Text('About App'),
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Navigate to about page
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('About App - Coming Soon')),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.newspaper),
                  title: const Text('Cyber News'),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/news');
                  },
                ),
                // Admin Dashboard - Only visible for admins
                authState.maybeWhen(
                  data: (user) => user?.role == 'admin'
                      ? ListTile(
                          leading: const Icon(Icons.admin_panel_settings),
                          title: const Text('Admin Dashboard'),
                          onTap: () {
                            Navigator.pop(context);
                            context.push('/admin');
                          },
                        )
                      : const SizedBox.shrink(),
                  orElse: () => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          // Theme Toggle Section
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            child: Consumer(
              builder: (context, ref, child) {
                final isDarkMode = ref.watch(themeProvider);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Theme',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.light_mode),
                            label: const Text('Light'),
                            onPressed: () {
                              ref.read(themeProvider.notifier).setLightMode();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: !isDarkMode
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey.shade600,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.dark_mode),
                            label: const Text('Dark'),
                            onPressed: () {
                              ref.read(themeProvider.notifier).setDarkMode();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDarkMode
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey.shade600,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
          const Divider(),
          // Logout Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  Navigator.pop(context);
                  await ref.read(authProvider.notifier).logout();
                  if (context.mounted) {
                    context.go('/login');
                  }
                },
                child: const Text('Logout'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
