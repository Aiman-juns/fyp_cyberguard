import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../core/services/avatar_service.dart';
import '../../../config/supabase_config.dart';
import '../../support/screens/emergency_support_screen.dart';
import '../../../shared/widgets/emergency_fab.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({Key? key}) : super(key: key);

  Future<Map<String, dynamic>> _fetchProgress() async {
    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId == null) return {'completed': 0, 'total': 0};

      final response = await SupabaseConfig.client
          .from('user_progress')
          .select('is_completed')
          .eq('user_id', userId);

      final data = response as List;
      final completed = data.where((item) => item['is_completed'] == true).length;
      final total = data.length;

      return {'completed': completed, 'total': total};
    } catch (e) {
      return {'completed': 0, 'total': 0};
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1117) : const Color(0xFFF8F9FA),
      body: SafeArea(
        child: authState.when(
          data: (user) {
            if (user == null) {
              return Center(child: Text('Please log in'));
            }

            final avatar = AvatarService.getAvatarById(user.avatarId);

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Custom Header
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        // User Avatar
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: avatar.color,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: avatar.color.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            avatar.icon,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Greeting
                        Expanded(
                          child: Text(
                            'Hello, ${user.fullName.split(' ')[0]} 👋',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        // Search Icon (inactive)
                        IconButton(
                          icon: Icon(Icons.search),
                          onPressed: () {
                            // No action
                          },
                        ),
                        // Settings Icon
                        IconButton(
                          icon: Icon(Icons.settings),
                          onPressed: () {
                            Scaffold.of(context).openDrawer();
                          },
                        ),
                      ],
                    ),
                  ),

                  // Banner with gradient
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Container(
                      height: 180,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF6A11CB),
                            Color(0xFF2575FC),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF2575FC).withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // Watermark Icon
                          Positioned(
                            right: -20,
                            bottom: -20,
                            child: Icon(
                              Icons.shield_outlined,
                              size: 150,
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                          // Text Content
                          Positioned(
                            left: 24,
                            top: 0,
                            bottom: 0,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Secure Your',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Digital Life',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Learn to protect yourself online',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Learning Progress Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'Learning Progress',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: FutureBuilder<Map<String, dynamic>>(
                      future: _fetchProgress(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }

                        final data = snapshot.data ?? {'completed': 0, 'total': 0};
                        final completed = data['completed'] as int;
                        final total = data['total'] as int;
                        final percentage = total > 0 ? (completed / total * 100) : 0;

                        return Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey.shade900 : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Overall Progress',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '${percentage.toStringAsFixed(0)}%',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.purple,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: percentage / 100,
                                  minHeight: 10,
                                  backgroundColor: Colors.grey.shade300,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.purple,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '$completed of $total lessons completed',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Dashboard Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'Dashboard',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Two Large Cards: Training Hub and Resources
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        // Card 1: Training Hub
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              context.push('/training');
                            },
                            child: Container(
                              height: 200,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.deepPurple.shade900.withOpacity(0.3)
                                    : Colors.deepPurple.shade200,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.deepPurple.withOpacity(0.2),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.model_training,
                                    size: 64,
                                    color: Colors.deepPurple,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Training Hub',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Card 2: Resources
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              context.push('/resources');
                            },
                            child: Container(
                              height: 200,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.blue.shade900.withOpacity(0.3)
                                    : Colors.blue.shade200,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.2),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.auto_stories,
                                    size: 64,
                                    color: Colors.blue,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Resources',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            );
          },
          loading: () => Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Error: $error')),
        ),
      ),
      floatingActionButton: const EmergencyFAB(),
    );
  }
}
