import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/supabase_config.dart';
import '../../resources/providers/resources_provider.dart';
import '../../training/providers/training_provider.dart';
import '../../training/screens/phishing_screen.dart';
import '../../training/screens/password_dojo_screen.dart';
import '../../training/screens/cyber_attack_screen.dart';

class GlobalSearchScreen extends ConsumerStatefulWidget {
  const GlobalSearchScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends ConsumerState<GlobalSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      _isSearching = query.isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    final userId = SupabaseConfig.client.auth.currentUser?.id;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Search Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF1E293B)
                    : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Search modules, resources...',
                        border: InputBorder.none,
                        hintStyle: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 16,
                        ),
                      ),
                      style: const TextStyle(fontSize: 16),
                      onChanged: _performSearch,
                    ),
                  ),
                  if (_searchQuery.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _performSearch('');
                      },
                    ),
                ],
              ),
            ),

            // Search Results
            Expanded(
              child: _isSearching
                  ? _buildSearchResults(userId)
                  : _buildInitialView(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Search Across',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 16),
          _buildCategoryCard(
            icon: Icons.school,
            title: 'Training Modules',
            description: 'Phishing, Password Security, Cyber Attacks',
            color: const Color(0xFF10B981),
          ),
          const SizedBox(height: 12),
          _buildCategoryCard(
            icon: Icons.auto_stories,
            title: 'Learning Resources',
            description: 'Articles, videos, and guides',
            color: const Color(0xFF3B82F6),
          ),
          const SizedBox(height: 12),
          _buildCategoryCard(
            icon: Icons.history,
            title: 'Activity History',
            description: 'Your past questions and attempts',
            color: const Color(0xFF8B5CF6),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1E293B)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(String? userId) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Training Modules Results
          _buildTrainingModulesResults(),

          // Resources Results
          _buildResourcesResults(),

          // Activity History Results
          if (userId != null) _buildActivityHistoryResults(userId),
        ],
      ),
    );
  }

  Widget _buildTrainingModulesResults() {
    final modules = [
      {
        'title': 'Phishing Email Detection',
        'description': 'Learn to identify phishing emails',
        'icon': Icons.email,
        'color': const Color(0xFFF59E0B),
        'moduleName': 'Phishing Email Detection',
        'screenBuilder': (int difficulty) =>
            PhishingScreen(difficulty: difficulty),
      },
      {
        'title': 'Password Security',
        'description': 'Master password best practices',
        'icon': Icons.lock,
        'color': const Color(0xFF8B5CF6),
        'moduleName': 'Password Dojo',
        'screenBuilder': (int difficulty) =>
            PasswordDojoLoaderScreen(difficulty: difficulty),
      },
      {
        'title': 'Cyber Attack Recognition',
        'description': 'Identify different attack types',
        'icon': Icons.warning,
        'color': const Color(0xFFEF4444),
        'moduleName': 'Threat Recognition',
        'screenBuilder': (int difficulty) =>
            CyberAttackScreen(difficulty: difficulty),
      },
    ];

    final filteredModules = modules.where((module) {
      return module['title'].toString().toLowerCase().contains(_searchQuery) ||
          module['description'].toString().toLowerCase().contains(_searchQuery);
    }).toList();

    if (filteredModules.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Training Modules', filteredModules.length),
        const SizedBox(height: 12),
        ...filteredModules.map(
          (module) => _buildResultCard(
            icon: module['icon'] as IconData,
            title: module['title'] as String,
            description: module['description'] as String,
            color: module['color'] as Color,
            onTap: () {
              Navigator.pop(context);
              _showLevelSelectionDialog(
                context,
                module['moduleName'] as String,
                module['screenBuilder'] as Widget Function(int),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  void _showLevelSelectionDialog(
    BuildContext context,
    String moduleName,
    Widget Function(int difficulty) screenBuilder,
  ) {
    showDialog(
      context: context,
      builder: (context) => _LevelSelectionDialog(
        moduleName: moduleName,
        onLevelSelected: (difficulty) {
          Navigator.pop(context); // Close dialog
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => screenBuilder(difficulty)),
          );
        },
      ),
    );
  }

  Widget _buildResourcesResults() {
    final resourcesAsync = ref.watch(resourcesProvider);

    return resourcesAsync.when(
      data: (resources) {
        final filteredResources = resources.where((resource) {
          final description = resource.description?.toLowerCase() ?? '';
          final title = resource.title.toLowerCase();
          final category = resource.category.toLowerCase();

          return title.contains(_searchQuery) ||
              description.contains(_searchQuery) ||
              category.contains(_searchQuery);
        }).toList();

        if (filteredResources.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Learning Resources', filteredResources.length),
            const SizedBox(height: 12),
            ...filteredResources
                .take(5)
                .map(
                  (resource) => _buildResultCard(
                    icon: Icons.auto_stories,
                    title: resource.title,
                    description:
                        resource.description ??
                        'Learn about ${resource.category}',
                    color: const Color(0xFF3B82F6),
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/resource/${resource.id}');
                    },
                  ),
                ),
            const SizedBox(height: 24),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildActivityHistoryResults(String userId) {
    final recentActivityAsync = ref.watch(recentActivityProvider(userId));

    return recentActivityAsync.when(
      data: (activities) {
        final filteredActivities = activities.where((activity) {
          final question = activity.question;
          if (question == null) return false;
          return question.content.toLowerCase().contains(_searchQuery) ||
              question.moduleType.toLowerCase().contains(_searchQuery);
        }).toList();

        if (filteredActivities.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Activity History', filteredActivities.length),
            const SizedBox(height: 12),
            ...filteredActivities.take(5).map((activity) {
              final question = activity.question!;
              final isCorrect = activity.isCorrect;
              return _buildResultCard(
                icon: isCorrect ? Icons.check_circle : Icons.cancel,
                title:
                    'Level ${question.difficulty} - ${_getModuleName(question.moduleType)}',
                description: isCorrect ? 'Correct answer' : 'Incorrect answer',
                color: isCorrect ? Colors.green : Colors.red,
                onTap: () {
                  // Could show the question review dialog here
                },
              );
            }),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF3B82F6).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3B82F6),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1E293B)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200, width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  String _getModuleName(String moduleType) {
    switch (moduleType) {
      case 'phishing':
        return 'Phishing Email';
      case 'password':
        return 'Password Security';
      case 'attack':
        return 'Cyber Attack';
      default:
        return 'Training';
    }
  }
}

class _LevelSelectionDialog extends ConsumerWidget {
  final String moduleName;
  final Function(int difficulty) onLevelSelected;

  const _LevelSelectionDialog({
    required this.moduleName,
    required this.onLevelSelected,
  });

  String _getModuleType(String moduleName) {
    if (moduleName.contains('Phishing')) return 'phishing';
    if (moduleName.contains('Password')) return 'password';
    if (moduleName.contains('Attack')) return 'attack';
    return '';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    final moduleType = _getModuleType(moduleName);

    return AlertDialog(
      title: const Text('Select Difficulty Level'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose the difficulty level for $moduleName',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            if (userId != null && moduleType.isNotEmpty)
              _LevelListWithProgress(
                userId: userId,
                moduleType: moduleType,
                onLevelSelected: onLevelSelected,
              )
            else
              _DefaultLevelList(onLevelSelected: onLevelSelected),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

class _DefaultLevelList extends StatelessWidget {
  final Function(int) onLevelSelected;

  const _DefaultLevelList({required this.onLevelSelected});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        final level = index + 1;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getLevelColor(level),
              child: Text(
                '$level',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text('Level $level'),
            subtitle: Text(_getLevelDescription(level)),
            trailing: const Icon(Icons.arrow_forward),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.shade700
                    : Colors.grey.shade300,
              ),
            ),
            onTap: () => onLevelSelected(level),
          ),
        );
      }),
    );
  }

  Color _getLevelColor(int level) {
    switch (level) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  String _getLevelDescription(int level) {
    switch (level) {
      case 1:
        return 'Beginner - Easy questions';
      case 2:
        return 'Intermediate - Moderate difficulty';
      case 3:
        return 'Advanced - Challenging questions';
      default:
        return 'Select this level';
    }
  }
}

class _LevelListWithProgress extends ConsumerWidget {
  final String userId;
  final String moduleType;
  final Function(int) onLevelSelected;

  const _LevelListWithProgress({
    required this.userId,
    required this.moduleType,
    required this.onLevelSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(
      moduleProgressProvider((userId: userId, moduleType: moduleType)),
    );

    return progressAsync.when(
      data: (progressMap) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final level = index + 1;
            final progress = progressMap[level] ?? 0.0;
            final isCompleted = progress >= 1.0;
            final isInProgress = progress > 0 && progress < 1.0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getLevelColor(level),
                  child: isCompleted
                      ? const Icon(Icons.check, color: Colors.white)
                      : Text(
                          '$level',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                title: Row(
                  children: [
                    Text('Level $level'),
                    if (isInProgress)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'In Progress',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    if (isCompleted)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Completed',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                subtitle: Text(_getLevelDescription(level)),
                trailing: const Icon(Icons.arrow_forward),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: isCompleted
                        ? Colors.green.withOpacity(0.3)
                        : (Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey.shade700
                              : Colors.grey.shade300),
                  ),
                ),
                onTap: () => onLevelSelected(level),
              ),
            );
          }),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => _DefaultLevelList(onLevelSelected: onLevelSelected),
    );
  }

  Color _getLevelColor(int level) {
    switch (level) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  String _getLevelDescription(int level) {
    switch (level) {
      case 1:
        return 'Beginner - Easy questions';
      case 2:
        return 'Intermediate - Moderate difficulty';
      case 3:
        return 'Advanced - Challenging questions';
      default:
        return 'Select this level';
    }
  }
}
