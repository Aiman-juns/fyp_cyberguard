class Note {
  final String id;
  final String resourceId;
  final String content;
  final Duration timestamp;
  final DateTime createdAt;

  Note({
    required this.id,
    required this.resourceId,
    required this.content,
    required this.timestamp,
    required this.createdAt,
  });

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  String get formattedTimestamp {
    final minutes = timestamp.inMinutes;
    final seconds = timestamp.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
