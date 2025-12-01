import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../providers/resources_provider.dart';
import '../providers/notes_provider.dart';
import '../providers/progress_provider.dart';
import '../models/note_model.dart';

class ResourceDetailScreen extends ConsumerStatefulWidget {
  final String resourceId;

  const ResourceDetailScreen({Key? key, required this.resourceId})
    : super(key: key);

  @override
  ConsumerState<ResourceDetailScreen> createState() =>
      _ResourceDetailScreenState();
}

class _ResourceDetailScreenState extends ConsumerState<ResourceDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  YoutubePlayerController? _youtubeController;
  final TextEditingController _noteController = TextEditingController();

  DateTime? _lastUpdateTime;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _youtubeController?.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _initializeYoutubePlayer(String? videoUrl) {
    if (videoUrl == null) return;

    // Extract video ID from YouTube URL
    String? videoId;
    if (videoUrl.contains('youtube.com/watch?v=')) {
      videoId = videoUrl.split('v=')[1].split('&')[0];
    } else if (videoUrl.contains('youtu.be/')) {
      videoId = videoUrl.split('youtu.be/')[1].split('?')[0];
    }

    if (videoId != null) {
      _youtubeController = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(autoPlay: false, mute: false),
      )..addListener(_onVideoPositionChanged);
    }
  }

  void _onVideoPositionChanged() {
    if (_youtubeController == null) return;

    final isPlaying = _youtubeController!.value.isPlaying;

    if (isPlaying && _lastUpdateTime != null) {
      final timeDiff = DateTime.now().difference(_lastUpdateTime!);
      if (timeDiff.inSeconds >= 60) {
        // Update watch time every minute
        ref
            .read(progressProvider.notifier)
            .addWatchTime(widget.resourceId, timeDiff);
        _lastUpdateTime = DateTime.now();
      }
    } else if (isPlaying) {
      _lastUpdateTime = DateTime.now();
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _saveNote(String resourceId) {
    if (_noteController.text.trim().isEmpty) return;

    final currentPosition = _youtubeController?.value.position ?? Duration.zero;
    final note = Note(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      resourceId: resourceId,
      content: _noteController.text.trim(),
      timestamp: currentPosition,
      createdAt: DateTime.now(),
    );

    ref.read(notesProvider.notifier).addNote(note);
    _noteController.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final resourceAsync = ref.watch(resourceProvider(widget.resourceId));
    final notes = ref.watch(resourceNotesProvider(widget.resourceId));
    final progress = ref.watch(resourceProgressProvider(widget.resourceId));

    return Scaffold(
      backgroundColor: Colors.white,
      body: resourceAsync.when(
        data: (resource) {
          // Initialize YouTube player if not already initialized
          if (_youtubeController == null && resource.mediaUrl != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _initializeYoutubePlayer(resource.mediaUrl);
              setState(() {});
            });
          }

          return Column(
            children: [
              // Video Player Section
              _buildVideoPlayerSection(context, resource),
              // Tabs and Content
              Expanded(
                child: Column(
                  children: [
                    // Tab Bar
                    _buildTabBar(),
                    // Tab Content
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildOverviewTab(context, resource, progress),
                          _buildAboutTab(context, resource),
                          _buildNotesTab(context, resource, notes),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16.0),
              Text('Error loading resource: $error'),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoPlayerSection(BuildContext context, Resource resource) {
    return Container(
      color: Colors.black,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => context.pop(),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          resource.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${resource.category} • Lesson 1',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings, color: Colors.white),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            // Video Player
            if (_youtubeController != null && resource.mediaUrl != null)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: YoutubePlayer(
                  controller: _youtubeController!,
                  showVideoProgressIndicator: true,
                  progressIndicatorColor: const Color(0xFF9333EA),
                  progressColors: const ProgressBarColors(
                    playedColor: Color(0xFF9333EA),
                    handleColor: Color(0xFF9333EA),
                    bufferedColor: Colors.white24,
                    backgroundColor: Colors.white12,
                  ),
                ),
              )
            else
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  color: Colors.grey[900],
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
              ),
            // Video Controls
            if (_youtubeController != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        final currentPosition =
                            _youtubeController!.value.position;
                        final newPosition =
                            currentPosition - const Duration(seconds: 10);
                        _youtubeController!.seekTo(
                          newPosition < Duration.zero
                              ? Duration.zero
                              : newPosition,
                        );
                      },
                      icon: const Icon(
                        Icons.skip_previous,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Previous',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '1.0x',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        final currentPosition =
                            _youtubeController!.value.position;
                        final duration = _youtubeController!.metadata.duration;
                        final newPosition =
                            currentPosition + const Duration(seconds: 10);
                        _youtubeController!.seekTo(
                          newPosition > duration ? duration : newPosition,
                        );
                      },
                      icon: const Icon(Icons.skip_next, color: Colors.white),
                      label: const Text(
                        'Next',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.fullscreen, color: Colors.white),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorColor: const Color(0xFF9333EA),
        indicatorWeight: 3,
        labelColor: const Color(0xFF9333EA),
        unselectedLabelColor: Colors.grey,
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'About'),
          Tab(text: 'Notes'),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(
    BuildContext context,
    Resource resource,
    ResourceProgress progress,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Now Playing Card
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: const Color(0xFFF3E8FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF9333EA),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.school,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Now Playing',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF9333EA),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            resource.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ref
                          .read(progressProvider.notifier)
                          .markAsComplete(resource.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.white),
                              SizedBox(width: 8),
                              Text('Course marked as complete!'),
                            ],
                          ),
                          backgroundColor: const Color(0xFF10B981),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.check_circle, size: 20),
                    label: const Text('Mark as Complete'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Course Progress
          const Text(
            'Course Progress',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${progress.progressPercentage.toStringAsFixed(0)}% Complete',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              Text(
                '${progress.completedLessons} of ${progress.totalLessons} lessons',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAboutTab(BuildContext context, Resource resource) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description Section
          if (resource.description != null) ...[
            const Text(
              'Description',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              resource.description!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
          ],
          // What You'll Learn Section
          if (resource.learningObjectives != null &&
              resource.learningObjectives!.isNotEmpty) ...[
            const Text(
              'What You\'ll Learn',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            ...resource.learningObjectives!.map(
              (objective) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Color(0xFF10B981),
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        objective,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          // Special handling for Types of Cyber Attack
          if (resource.attackTypes != null &&
              resource.attackTypes!.isNotEmpty) ...[
            const SizedBox(height: 32),
            const Text(
              'Types of Cyber Attacks',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: resource.attackTypes!.length,
                itemBuilder: (context, index) {
                  final attackType = resource.attackTypes![index];
                  final attackData = _getAttackTypeData(attackType.title);
                  return Container(
                    width: 280,
                    margin: EdgeInsets.only(
                      right: index == resource.attackTypes!.length - 1 ? 0 : 16,
                    ),
                    child: Card(
                      elevation: 4,
                      shadowColor: Colors.black.withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              attackData['color']!.withOpacity(0.1),
                              attackData['color']!.withOpacity(0.05),
                            ],
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Icon Container
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: attackData['color']!.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  attackData['icon'] as IconData,
                                  color: attackData['color'],
                                  size: 28,
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Title
                              Text(
                                attackType.title,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.grey[900],
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Description
                              Expanded(
                                child: Text(
                                  attackType.description,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[700],
                                    height: 1.5,
                                  ),
                                  maxLines: 4,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNotesTab(
    BuildContext context,
    Resource resource,
    List<Note> notes,
  ) {
    final currentPosition = _youtubeController?.value.position ?? Duration.zero;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Note Input
          TextField(
            controller: _noteController,
            decoration: InputDecoration(
              hintText: 'Add a note for this lesson.....',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF9333EA),
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Timestamp: ${_formatDuration(currentPosition)}',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              ElevatedButton(
                onPressed: () => _saveNote(resource.id),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9333EA),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Save Note'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Notes List
          if (notes.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text(
                  'No notes yet. Add your first note above!',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            )
          else
            ...notes.map((note) => _buildNoteCard(note)),
        ],
      ),
    );
  }

  Widget _buildNoteCard(Note note) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.access_time, color: Color(0xFF9333EA), size: 20),
              const SizedBox(width: 8),
              Text(
                note.formattedTimestamp,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF9333EA),
                ),
              ),
              const Spacer(),
              Text(
                note.timeAgo,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            note.content,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ],
      ),
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
