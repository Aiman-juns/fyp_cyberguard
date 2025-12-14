import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/resources_provider.dart';
import '../providers/progress_provider.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../shared/widgets/custom_drawer.dart';

class ResourcesScreen extends ConsumerStatefulWidget {
  const ResourcesScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends ConsumerState<ResourcesScreen> {
  late TextEditingController _searchController;
  bool _showAllResources = false;
  bool _showAttackTypes = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resourcesAsync = ref.watch(resourcesProvider);
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Resources',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: resourcesAsync.when(
        data: (resources) {
          if (resources.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.library_books,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16.0),
                  Text(
                    'No resources available',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Header Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3B82F6).withOpacity(0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.library_books,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Learning Resources',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Explore security learning materials',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Learning Progress
                _buildLearningProgress(context, resources),
                const SizedBox(height: 28),
                // Header Row with "Learning Resources" and "See All"
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.library_books,
                            color: Color(0xFF3B82F6),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Learning Resources',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _showAllResources = !_showAllResources;
                        });
                      },
                      child: Text(
                        _showAllResources ? 'Show Less' : 'See All',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF3B82F6),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),
                // Resource List
                ...(_showAllResources ? resources : resources.take(3)).map((
                  resource,
                ) {
                  final progress = ref.watch(
                    resourceProgressProvider(resource.id),
                  );

                  // Special handling for Types of Cyber Attack
                  if (resource.title == 'Types of Cyber Attack' &&
                      resource.attackTypes != null &&
                      resource.attackTypes!.isNotEmpty) {
                    return _buildCyberAttackCard(context, resource, progress);
                  }

                  return _buildResourceCard(context, resource, progress);
                }).toList(),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
                const SizedBox(height: 16.0),
                Text(
                  'Error loading resources: $error',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16.0),
                ElevatedButton(
                  onPressed: () {
                    ref.invalidate(resourcesProvider);
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildResourceCard(
    BuildContext context,
    Resource resource,
    ResourceProgress progress,
  ) {
    final progressPercent = progress.progressPercentage;
    final remainingLessons = progress.totalLessons - progress.completedLessons;

    // Get resource color and icon based on title
    final resourceData = _getResourceData(resource.title);
    final resourceColor = resourceData['color'] as Color;
    final resourceIcon = resourceData['icon'] as IconData;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        onTap: () {
          context.push('/resource/${resource.id}');
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: resourceColor.withOpacity(0.3), width: 2),
            boxShadow: [
              BoxShadow(
                color: resourceColor.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(18.0),
                child: Row(
                  children: [
                    // Icon/Thumbnail
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            resourceColor,
                            resourceColor.withOpacity(0.7),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: resourceColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(resourceIcon, color: Colors.white, size: 32),
                    ),
                    const SizedBox(width: 16),
                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            resource.title,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            resource.description ?? '',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                remainingLessons > 0
                                    ? Icons.play_circle_outline
                                    : Icons.check_circle,
                                size: 16,
                                color: remainingLessons > 0
                                    ? resourceColor
                                    : const Color(0xFF10B981),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                remainingLessons > 0
                                    ? '$remainingLessons lesson${remainingLessons > 1 ? 's' : ''} remaining'
                                    : 'Completed',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: resourceColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${progressPercent.toStringAsFixed(0)}%',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: resourceColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Progress Bar
              if (progressPercent > 0 && progressPercent < 100)
                Container(
                  height: 8,
                  margin: const EdgeInsets.only(
                    left: 18,
                    right: 18,
                    bottom: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: (progressPercent / 100).clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            resourceColor,
                            resourceColor.withOpacity(0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _getResourceData(String title) {
    if (title.contains('Password')) {
      return {'color': const Color(0xFF3B82F6), 'icon': Icons.lock};
    } else if (title.contains('Phishing')) {
      return {'color': const Color(0xFFF59E0B), 'icon': Icons.email};
    } else if (title.contains('Network')) {
      return {'color': const Color(0xFF10B981), 'icon': Icons.wifi};
    }
    return {'color': const Color(0xFF3B82F6), 'icon': Icons.article};
  }

  Widget _buildCyberAttackCard(
    BuildContext context,
    Resource resource,
    ResourceProgress progress,
  ) {
    const cardColor = Color(0xFFEF4444);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        onTap: () {
          setState(() {
            _showAttackTypes = !_showAttackTypes;
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cardColor.withOpacity(0.3), width: 2),
            boxShadow: [
              BoxShadow(
                color: cardColor.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Icon Container
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [cardColor, cardColor.withOpacity(0.7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: cardColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.bug_report,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            resource.title,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${resource.attackTypes!.length} attack types',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Expand/Collapse Icon
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: cardColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _showAttackTypes
                            ? Icons.expand_less
                            : Icons.expand_more,
                        color: cardColor,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                if (_showAttackTypes) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  ...resource.attackTypes!.map((attackType) {
                    final attackData = _getAttackTypeData(attackType.title);
                    final attackProgressId = '${resource.id}_${attackType.id}';
                    final attackProgress = ref.watch(
                      resourceProgressProvider(attackProgressId),
                    );
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: InkWell(
                        onTap: () {
                          context.push(
                            '/resource/${resource.id}?attackTypeId=${attackType.id}',
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: attackProgress.isCompleted
                                    ? Icon(
                                        Icons.check_circle,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        size: 24,
                                      )
                                    : Icon(
                                        attackData['icon'] as IconData,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        size: 24,
                                      ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            attackType.title,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        if (attackProgress.isCompleted)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .secondary
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              'Completed',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.secondary,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      attackType.description,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLearningProgress(
    BuildContext context,
    List<Resource> resources,
  ) {
    // Calculate total progress
    int coursesInProgress = 0;
    double totalProgress = 0.0;
    int totalCourses = 0;

    for (var resource in resources) {
      // For "Types of Cyber Attack", count individual attack types
      if (resource.title == 'Types of Cyber Attack' &&
          resource.attackTypes != null &&
          resource.attackTypes!.isNotEmpty) {
        // Count each attack type separately
        for (var attackType in resource.attackTypes!) {
          final attackProgressId = '${resource.id}_${attackType.id}';
          final attackProgress = ref.watch(
            resourceProgressProvider(attackProgressId),
          );
          totalCourses++;
          if (attackProgress.isCompleted) {
            coursesInProgress++;
            totalProgress += 100.0;
          } else if (attackProgress.minutesWatched > 0) {
            coursesInProgress++;
            totalProgress += 50.0; // Partial progress
          } else {
            // Not started - still count in total but add 0 progress
            totalProgress += 0.0;
          }
        }
      } else {
        // Regular resource
        totalCourses++;
        final progress = ref.watch(resourceProgressProvider(resource.id));
        if (progress.isCompleted) {
          coursesInProgress++;
          totalProgress += 100.0;
        } else if (progress.completedLessons > 0 ||
            progress.minutesWatched > 0) {
          coursesInProgress++;
          totalProgress += progress.progressPercentage;
        } else {
          // Not started
          totalProgress += 0.0;
        }
      }
    }

    if (totalCourses > 0) {
      totalProgress = totalProgress / totalCourses;
    }

    return Column(
      children: [
        const SizedBox(height: 16),
        // Learning Progress Card
        Container(
          margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF9333EA), Color(0xFF7E22CE)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF9333EA).withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.trending_up,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Learning Progress',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$coursesInProgress course${coursesInProgress != 1 ? 's' : ''} in progress',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${totalProgress.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: (totalProgress / 100).clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF97316),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Map<String, dynamic> _getAttackTypeData(String attackType) {
    switch (attackType) {
      case 'Clickjacking':
        return {
          'icon': Icons.touch_app,
          'color': const Color(0xFFEF4444), // Red
        };
      case 'Phishing Email':
        return {
          'icon': Icons.email,
          'color': const Color(0xFFF59E0B), // Amber
        };
      case 'Brute Force Attack':
        return {
          'icon': Icons.lock_open,
          'color': const Color(0xFF8B5CF6), // Purple
        };
      case 'DNS Poisoning':
        return {
          'icon': Icons.dns,
          'color': const Color(0xFF10B981), // Green
        };
      case 'Credential Stuffing':
        return {
          'icon': Icons.key,
          'color': const Color(0xFF3B82F6), // Blue
        };
      default:
        return {'icon': Icons.security, 'color': const Color(0xFF9333EA)};
    }
  }
}
