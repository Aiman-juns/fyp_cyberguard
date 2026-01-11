import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'dart:io';
import '../providers/resources_provider.dart';
import '../providers/notes_provider.dart';
import '../providers/video_progress_provider.dart';
import '../providers/progress_provider.dart';
import '../models/note_model.dart';
import '../models/video_progress_model.dart';
import '../../performance/providers/performance_provider.dart';
import '../../profile/providers/profile_analytics_provider.dart';
import '../../../core/widgets/achievement_dialog.dart';
import '../../../core/services/achievement_detector.dart';

class ResourceDetailScreen extends ConsumerStatefulWidget {
  final String resourceId;
  final String? attackTypeId;

  const ResourceDetailScreen({
    Key? key,
    required this.resourceId,
    this.attackTypeId,
  }) : super(key: key);

  @override
  ConsumerState<ResourceDetailScreen> createState() =>
      _ResourceDetailScreenState();
}

class _ResourceDetailScreenState extends ConsumerState<ResourceDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  VideoPlayerController? _videoController;
  YoutubePlayerController? _youtubeController;
  bool _isYouTubeVideo = false;
  final TextEditingController _noteController = TextEditingController();
  bool _isVideoInitialized = false;
  String? _currentMediaUrl; // Track current URL
  bool _showVideoOverlay = true; // Control overlay visibility
  DateTime? _lastUpdateTime;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _startOverlayTimer();
  }

  void _startOverlayTimer() {
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _showVideoOverlay = false;
        });
      }
    });
  }

  void _toggleOverlay() {
    setState(() {
      _showVideoOverlay = !_showVideoOverlay;
    });
    if (_showVideoOverlay) {
      _startOverlayTimer();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _videoController?.dispose();
    _youtubeController?.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _initializeVideoPlayer(String? videoPath) async {
    if (videoPath == null || videoPath.isEmpty) return;

    try {
      // Clean up the video path (remove extra whitespace/newlines)
      final cleanPath = videoPath.trim();

      // Check if it's a YouTube URL
      if (cleanPath.contains('youtube.com') || cleanPath.contains('youtu.be')) {
        final videoId = YoutubePlayer.convertUrlToId(cleanPath);
        if (videoId != null && videoId.isNotEmpty) {
          _isYouTubeVideo = true;
          _youtubeController = YoutubePlayerController(
            initialVideoId: videoId,
            flags: const YoutubePlayerFlags(autoPlay: false, mute: false),
          );
          if (mounted) {
            setState(() {
              _isVideoInitialized = true;
            });
          }
          return;
        } else {
          // Failed to extract video ID
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Invalid YouTube URL: $cleanPath'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }

      // Handle local video assets
      _isYouTubeVideo = false;
      String assetPath;
      if (cleanPath.contains('\\') || cleanPath.contains('/')) {
        final filename = cleanPath.split(RegExp(r'[/\\]')).last;
        assetPath = 'assets/videos/$filename';
      } else {
        assetPath = 'assets/videos/$videoPath';
      }

      _videoController = VideoPlayerController.asset(assetPath)
        ..addListener(_onVideoPositionChanged)
        ..initialize()
            .then((_) async {
              if (mounted) {
                setState(() {
                  _isVideoInitialized = true;
                });

                // Restore saved progress after initialization
                try {
                  final progressId = widget.attackTypeId != null
                      ? '${widget.resourceId}_${widget.attackTypeId}'
                      : widget.resourceId;

                  print('🔍 Loading progress for: $progressId');

                  // Load progress from FutureProvider
                  final progressAsync = await ref.read(
                    videoProgressProvider(progressId).future,
                  );

                  print('🔍 Progress loaded: $progressAsync');

                  // Use the loaded progress
                  final progress = progressAsync;

                  if (progress != null && progress.watchPercentage > 0) {
                    final duration = _videoController!.value.duration;
                    final savedPosition =
                        duration * (progress.watchPercentage / 100);
                    await _videoController!.seekTo(savedPosition);
                    print(
                      '✅ Restored video position: ${progress.watchPercentage}% at ${savedPosition.inSeconds}s',
                    );
                  } else {
                    print('ℹ️ No saved progress found for $progressId');
                  }
                } catch (e) {
                  print('❌ Error restoring video progress: $e');
                }
              }
            })
            .catchError((error) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Error loading video: $error\nPath: $assetPath',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error initializing video: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onVideoPositionChanged() async {
    if (_videoController == null || !_videoController!.value.isInitialized)
      return;

    final isPlaying = _videoController!.value.isPlaying;
    final position = _videoController!.value.position;
    final duration = _videoController!.value.duration;

    if (isPlaying && duration.inMilliseconds > 0) {
      // Update progress every 30 seconds
      if (_lastUpdateTime == null ||
          DateTime.now().difference(_lastUpdateTime!).inSeconds >= 30) {
        final watchPercentage =
            (position.inMilliseconds / duration.inMilliseconds * 100).clamp(
              0.0,
              100.0,
            );

        try {
          final progressId = widget.attackTypeId != null
              ? '${widget.resourceId}_${widget.attackTypeId}'
              : widget.resourceId;
          await VideoProgressService.updateProgress(
            resourceId: progressId,
            watchPercentage: watchPercentage,
            watchDurationSeconds: position.inSeconds,
          );
          // Invalidate to reload fresh data
          ref.invalidate(videoProgressProvider(progressId));
        } catch (e) {
          print('Error updating video progress: $e');
        }

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

    final currentPosition = _videoController?.value.position ?? Duration.zero;
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Use combined ID for progress tracking if attackTypeId is provided
    final progressId = widget.attackTypeId != null
        ? '${widget.resourceId}_${widget.attackTypeId}'
        : widget.resourceId;
    final progress = ref.watch(videoProgressProvider(progressId));

    return Scaffold(
      backgroundColor: isDark ? Colors.grey.shade900 : Colors.white,
      body: resourceAsync.when(
        data: (resource) {
          // Determine which video URL to use
          String? videoUrl = resource.mediaUrl;

          // If attackTypeId is provided, find and use that attack type's video
          if (widget.attackTypeId != null && resource.attackTypes != null) {
            final attackType = resource.attackTypes!.firstWhere(
              (type) => type.id == widget.attackTypeId,
              orElse: () => resource.attackTypes!.first,
            );
            videoUrl = attackType.mediaUrl ?? resource.mediaUrl;
          }

          // Initialize video player if URL changed or not initialized
          if (videoUrl != null &&
              videoUrl.isNotEmpty &&
              _currentMediaUrl != videoUrl) {
            // Clean up old controllers
            _videoController?.dispose();
            _videoController = null;
            _youtubeController?.dispose();
            _youtubeController = null;
            _isVideoInitialized = false;
            _currentMediaUrl = videoUrl;

            // Initialize new video
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _initializeVideoPlayer(videoUrl);
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
    final screenSize = MediaQuery.of(context).size;
    final orientation = MediaQuery.of(context).orientation;
    
    return Container(
      color: Colors.black,
      width: double.infinity,
      height: orientation == Orientation.landscape 
          ? screenSize.height 
          : screenSize.width * 9 / 16, // 16:9 aspect ratio for portrait
      child: Stack(
        children: [
          // Video Player
          Positioned.fill(
            child: _isVideoInitialized && _isYouTubeVideo && _youtubeController != null
            ? YoutubePlayerBuilder(
                        onEnterFullScreen: () {
                          SystemChrome.setPreferredOrientations([
                            DeviceOrientation.landscapeLeft,
                            DeviceOrientation.landscapeRight,
                          ]);
                        },
                        onExitFullScreen: () {
                          SystemChrome.setPreferredOrientations([
                            DeviceOrientation.portraitUp,
                            DeviceOrientation.portraitDown,
                          ]);
                        },
                        player: YoutubePlayer(
                          controller: _youtubeController!,
                          showVideoProgressIndicator: true,
                          progressIndicatorColor: const Color(0xFF9333EA),
                          progressColors: const ProgressBarColors(
                            playedColor: Color(0xFF9333EA),
                            handleColor: Color(0xFF9333EA),
                          ),
                          bottomActions: [
                            const SizedBox(width: 14.0),
                            CurrentPosition(),
                            const SizedBox(width: 8.0),
                            ProgressBar(
                              isExpanded: true,
                              colors: const ProgressBarColors(
                                playedColor: Color(0xFF9333EA),
                                handleColor: Color(0xFF9333EA),
                              ),
                            ),
                            RemainingDuration(),
                            const SizedBox(width: 8.0),
                            FullScreenButton(),
                          ],
                        ),
                        builder: (context, player) => player,
                      )
                    : _isVideoInitialized && _videoController != null
                        ? GestureDetector(
                            onTap: _toggleOverlay,
                            child: VideoPlayer(_videoController!),
                          )
                        : Container(
                            color: Colors.grey[900],
                            child: Center(
                              child: resource.mediaUrl == null || resource.mediaUrl!.isEmpty
                                  ? Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.video_library_outlined,
                                          size: 64,
                                          color: Colors.white54,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Video content coming soon',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'This lesson will be available shortly',
                                          style: TextStyle(
                                            color: Colors.white54,
                                            fontSize: 12,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    )
                                  : const CircularProgressIndicator(
                                      color: Colors.white,
                                    ),
                            ),
                          ),
                  ),
                  
                  // Auto-hiding Overlay Header
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: AnimatedOpacity(
                      opacity: _showVideoOverlay ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: IgnorePointer(
                        ignoring: !_showVideoOverlay,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.7),
                                Colors.transparent,
                              ],
                            ),
                          ),
                          child: SafeArea(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                children: [
                                  const SizedBox(width: 48), // Space for back button
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          resource.title,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            shadows: [
                                              Shadow(
                                                offset: Offset(0, 1),
                                                blurRadius: 3.0,
                                                color: Colors.black,
                                              ),
                                            ],
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          '${resource.category} • Lesson 1',
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12,
                                            shadows: [
                                              Shadow(
                                                offset: Offset(0, 1),
                                                blurRadius: 3.0,
                                                color: Colors.black,
                                              ),
                                            ],
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.3),
                                      shape: BoxShape.circle,
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.settings, color: Colors.white),
                                      onPressed: () {},
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Play/Pause overlay for local videos
                  if (_isVideoInitialized && _videoController != null && _showVideoOverlay)
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            if (_videoController!.value.isPlaying) {
                              _videoController!.pause();
                            } else {
                              _videoController!.play();
                            }
                          });
                        },
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _videoController!.value.isPlaying
                                ? Icons.pause
                                : Icons.play_arrow,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                  
                  // Progress indicator at bottom for local videos
                  if (_isVideoInitialized && _videoController != null)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: VideoProgressIndicator(
                        _videoController!,
                        allowScrubbing: true,
                        colors: const VideoProgressColors(
                          playedColor: Color(0xFF9333EA),
                          bufferedColor: Colors.white24,
                          backgroundColor: Colors.white12,
                        ),
                      ),
                    ),
                  
                  // Auto-hiding Bottom Controls
                  if (_isVideoInitialized && _videoController != null)
                    Positioned(
                      bottom: 20,
                      left: 0,
                      right: 0,
                      child: AnimatedOpacity(
                        opacity: _showVideoOverlay ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 300),
                        child: IgnorePointer(
                          ignoring: !_showVideoOverlay,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: TextButton.icon(
                                onPressed: () {
                                  final currentPosition = _videoController!.value.position;
                                  final newPosition = currentPosition - const Duration(seconds: 10);
                                  _videoController!.seekTo(
                                    newPosition < Duration.zero ? Duration.zero : newPosition,
                                  );
                                },
                                icon: const Icon(Icons.replay_10, color: Colors.white, size: 20),
                                label: const Text(
                                  '-10s',
                                  style: TextStyle(color: Colors.white, fontSize: 12),
                                ),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                onPressed: () {
                                  setState(() {
                                    if (_videoController!.value.isPlaying) {
                                      _videoController!.pause();
                                    } else {
                                      _videoController!.play();
                                    }
                                  });
                                },
                                icon: Icon(
                                  _videoController!.value.isPlaying
                                      ? Icons.pause
                                      : Icons.play_arrow,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: TextButton.icon(
                                onPressed: () {
                                  final currentPosition = _videoController!.value.position;
                                  final duration = _videoController!.value.duration;
                                  final newPosition = currentPosition + const Duration(seconds: 10);
                                  _videoController!.seekTo(
                                    newPosition > duration ? duration : newPosition,
                                  );
                                },
                                icon: const Icon(Icons.forward_10, color: Colors.white, size: 20),
                                label: const Text(
                                  '+10s',
                                  style: TextStyle(color: Colors.white, fontSize: 12),
                                ),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
          
          // Back Button (Always Visible - placed last to be on top)
          Positioned(
            top: 8,
            left: 8,
            child: SafeArea(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () {
                    SystemChrome.setPreferredOrientations([
                      DeviceOrientation.portraitUp,
                      DeviceOrientation.portraitDown,
                    ]);
                    context.pop();
                  },
                ),
              ),
            ),
          ),
        ],
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
    AsyncValue<VideoProgressModel?> progressAsync,
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
                    onPressed: () async {
                      try {
                        // Get achievements BEFORE marking complete
                        final achievementsBefore = await ref.read(userAchievementsProvider.future);
                        
                        // Calculate the correct progress ID
                        final progressId = widget.attackTypeId != null
                            ? '${resource.id}_${widget.attackTypeId}'
                            : resource.id;

                        // Update video progress in database - mark as 100% complete
                        await VideoProgressService.updateProgress(
                          resourceId: progressId,
                          watchPercentage: 100.0,
                          watchDurationSeconds:
                              _videoController?.value.duration.inSeconds ?? 0,
                        );

                        // ALSO update the resource progress provider (for Resources list screen)
                        ref
                            .read(progressProvider.notifier)
                            .markAsComplete(progressId);

                        // Force refresh providers
                        ref.invalidate(videoProgressProvider(progressId));
                        ref.refresh(performanceProvider);
                        ref.refresh(profileAnalyticsProvider);
                        
                        // CRITICAL: Invalidate achievements to force fresh fetch
                        ref.invalidate(userAchievementsProvider);

                        // Get achievements AFTER marking complete
                        final achievementsAfter = await ref.read(userAchievementsProvider.future);
                        
                        // Detect new unlocks
                        final newAchievements = AchievementDetector.detectNewAchievements(
                          previousAchievements: achievementsBefore,
                          currentAchievements: achievementsAfter,
                        );

                        // Trigger UI rebuild
                        if (mounted) {
                          setState(() {});
                        }

                        // Show achievement dialogs first
                        if (newAchievements.isNotEmpty && context.mounted) {
                          for (final achievement in newAchievements) {
                            await AchievementDialog.show(context, achievement);
                          }
                        }

                        // Show success message
                        if (context.mounted) {
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
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
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
          progressAsync.when(
            data: (videoProgress) {
              final progressPercentage = videoProgress?.watchPercentage ?? 0.0;
              final isCompleted = videoProgress?.completed ?? false;
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${progressPercentage.toStringAsFixed(0)}% Complete',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    isCompleted ? 'Completed' : 'In Progress',
                    style: TextStyle(
                      fontSize: 14,
                      color: isCompleted ? Colors.green[600] : Colors.grey[600],
                    ),
                  ),
                ],
              );
            },
            loading: () => const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Loading...', style: TextStyle(fontSize: 16)),
                Text('--', style: TextStyle(fontSize: 14)),
              ],
            ),
            error: (_, __) => const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('0% Complete', style: TextStyle(fontSize: 16)),
                Text('Not Started', style: TextStyle(fontSize: 14)),
              ],
            ),
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
    final currentPosition = _videoController?.value.position ?? Duration.zero;

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
