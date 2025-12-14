import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../auth/screens/login_screen.dart';
import '../auth/screens/register_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/training/screens/training_hub_screen.dart';
import '../features/training/screens/device_shield_screen.dart';
import '../features/resources/screens/resources_screen.dart';
import '../features/resources/screens/resource_detail_screen.dart';
import '../features/news/screens/news_screen.dart';
import '../features/news/screens/news_detail_screen.dart';
import '../features/games/screens/games_screen.dart';
import '../features/assistant/screens/assistant_screen.dart';
import '../features/performance/screens/performance_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/admin/screens/admin_dashboard_screen.dart';
import '../shared/widgets/custom_drawer.dart';
import '../shared/widgets/custom_bottom_nav.dart';

/// Main Dashboard after login - Shows user features
class UserDashboardScreen extends ConsumerStatefulWidget {
  const UserDashboardScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<UserDashboardScreen> createState() =>
      _UserDashboardScreenState();
}

class _UserDashboardScreenState extends ConsumerState<UserDashboardScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _userScreens = [
    HomeScreen(),
    GamesScreen(),
    AssistantScreen(),
    PerformanceScreen(),
    ProfileScreen(),
  ];

  static const List<String> _titles = [
    'CyberGuard HQ',
    'Games',
    'Assistant',
    'Performance',
    'Profile',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // All screens: no AppBar, only home has drawer
    if (_selectedIndex == 0) {
      return Scaffold(
        drawer: const CustomDrawer(),
        body: _userScreens[_selectedIndex],
        bottomNavigationBar: CustomBottomNav(
          currentIndex: _selectedIndex,
          onTabChanged: _onItemTapped,
        ),
      );
    }

    // Other screens: no AppBar, no drawer
    return Scaffold(
      body: _userScreens[_selectedIndex],
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _selectedIndex,
        onTabChanged: _onItemTapped,
      ),
    );
  }
}

/// Admin Dashboard Screen - Shows admin features
/// Removed wrapper because AdminDashboardScreen already has AppBar and Drawer

/// GoRouter Configuration for CyberGuard
///
/// Routes:
/// - /login - Login screen
/// - /register - Registration screen
/// - /dashboard - User dashboard (5 features)
/// - /admin - Admin dashboard
class RouterConfig {
  static final GoRouter router = GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      // Phase 1: Simple routing without auth check
      // Auth checking will be added in Phase 2 with Riverpod
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) =>
            MaterialPage(key: state.pageKey, child: const LoginScreen()),
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (context, state) =>
            MaterialPage(key: state.pageKey, child: const RegisterScreen()),
      ),
      GoRoute(
        path: '/dashboard',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const UserDashboardScreen(),
        ),
      ),
      GoRoute(
        path: '/admin',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const AdminDashboardScreen(),
        ),
      ),
      GoRoute(
        path: '/training',
        builder: (context, state) => Scaffold(
          appBar: AppBar(title: const Text('Training Hub'), centerTitle: true),
          body: const TrainingHubScreen(),
        ),
      ),
      GoRoute(
        path: '/device-shield',
        builder: (context, state) => const DeviceShieldScreen(),
      ),
      GoRoute(
        path: '/resources',
        builder: (context, state) => const ResourcesScreen(),
      ),
      GoRoute(path: '/news', builder: (context, state) => const NewsScreen()),
      GoRoute(
        path: '/resource/:id',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          final attackTypeId = state.uri.queryParameters['attackTypeId'];
          return MaterialPage(
            key: state.pageKey,
            child: ResourceDetailScreen(
              resourceId: id,
              attackTypeId: attackTypeId,
            ),
          );
        },
      ),
      GoRoute(
        path: '/news/:id',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          return MaterialPage(
            key: state.pageKey,
            child: NewsDetailScreen(newsId: id),
          );
        },
      ),
      GoRoute(
        path: '/',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const UserDashboardScreen(),
        ),
      ),
    ],
    errorPageBuilder: (context, state) => MaterialPage(
      child: Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64),
              const SizedBox(height: 16),
              const Text('Page not found'),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => context.go('/'),
                child: const Text('Go Home'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
