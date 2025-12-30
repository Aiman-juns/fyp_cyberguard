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
          // Enhanced Profile Header with Logo and Gradient
          authState.when(
            data: (user) {
              return Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF00B4DB),
                      Color(0xFF0083B0),
                      Color(0xFF1A237E),
                    ],
                    stops: [0.0, 0.5, 1.0],
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 20.0,
                      horizontal: 16.0,
                    ),
                    child: Column(
                      children: [
                        // Logo Section
                        Image.asset(
                          'assets/images/cyberguard_logo1.png',
                          width: 180,
                          height: 180,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 180,
                              height: 180,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF00B4DB),
                                    Color(0xFF0083B0),
                                  ],
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.shield_outlined,
                                size: 90,
                                color: Colors.white,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
            loading: () => Container(
              height: 280,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF00B4DB),
                    Color(0xFF0083B0),
                    Color(0xFF1A237E),
                  ],
                ),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
            error: (error, stackTrace) => Container(
              height: 280,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.red.shade400, Colors.red.shade700],
                ),
              ),
              child: const Center(
                child: Icon(Icons.error, color: Colors.white, size: 48),
              ),
            ),
          ),
          // Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.info, color: Colors.purple.shade700),
                  ),
                  title: const Text(
                    'About App',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey.shade400,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/about');
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.newspaper, color: Colors.orange.shade700),
                  ),
                  title: const Text(
                    'Cyber News',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey.shade400,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/news');
                  },
                ),
                // Admin Dashboard - Only visible for admins
                authState.maybeWhen(
                  data: (user) => user?.role == 'admin'
                      ? ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.admin_panel_settings,
                              color: Colors.red.shade700,
                            ),
                          ),
                          title: const Text(
                            'Admin Dashboard',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          trailing: Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.grey.shade400,
                          ),
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
          Container(
            margin: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.grey.shade50, Colors.grey.shade100],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200, width: 1),
            ),
            child: Consumer(
              builder: (context, ref, child) {
                final isDarkMode = ref.watch(themeProvider);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.palette,
                            size: 18,
                            color: Colors.purple.shade700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Theme',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade800,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.light_mode, size: 18),
                            label: const Text(
                              'Light',
                              style: TextStyle(fontSize: 13),
                            ),
                            onPressed: () {
                              ref.read(themeProvider.notifier).setLightMode();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: !isDarkMode
                                  ? Color(0xFF00B4DB)
                                  : Colors.grey.shade300,
                              foregroundColor: !isDarkMode
                                  ? Colors.white
                                  : Colors.grey.shade700,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              elevation: !isDarkMode ? 2 : 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.dark_mode, size: 18),
                            label: const Text(
                              'Dark',
                              style: TextStyle(fontSize: 13),
                            ),
                            onPressed: () {
                              ref.read(themeProvider.notifier).setDarkMode();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDarkMode
                                  ? Color(0xFF1A237E)
                                  : Colors.grey.shade300,
                              foregroundColor: isDarkMode
                                  ? Colors.white
                                  : Colors.grey.shade700,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              elevation: isDarkMode ? 2 : 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
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
          const Divider(height: 1),
          // Logout Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.logout, size: 20),
                label: const Text(
                  'Logout',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                onPressed: () async {
                  await ref.read(authProvider.notifier).logout();
                  if (context.mounted) {
                    // Close drawer first
                    Navigator.of(context).pop();
                    // Navigate to login and clear all previous routes
                    context.go('/login');
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
