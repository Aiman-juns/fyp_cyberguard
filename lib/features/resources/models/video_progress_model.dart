class VideoProgressModel {
  final String id;
  final String userId;
  final String resourceId;
  final double watchPercentage;
  final int watchDurationSeconds;
  final bool completed;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? resource; // Resource data if included

  VideoProgressModel({
    required this.id,
    required this.userId,
    required this.resourceId,
    required this.watchPercentage,
    required this.watchDurationSeconds,
    required this.completed,
    this.createdAt,
    this.updatedAt,
    this.resource,
  });

  factory VideoProgressModel.fromJson(Map<String, dynamic> json) {
    return VideoProgressModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      resourceId: json['resource_id'] as String,
      watchPercentage: (json['watch_percentage'] as num).toDouble(),
      watchDurationSeconds: json['watch_duration_seconds'] as int,
      completed: json['completed'] as bool,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      resource: json['resources'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'resource_id': resourceId,
      'watch_percentage': watchPercentage,
      'watch_duration_seconds': watchDurationSeconds,
      'completed': completed,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      if (resource != null) 'resources': resource,
    };
  }

  VideoProgressModel copyWith({
    String? id,
    String? userId,
    String? resourceId,
    double? watchPercentage,
    int? watchDurationSeconds,
    bool? completed,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? resource,
  }) {
    return VideoProgressModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      resourceId: resourceId ?? this.resourceId,
      watchPercentage: watchPercentage ?? this.watchPercentage,
      watchDurationSeconds: watchDurationSeconds ?? this.watchDurationSeconds,
      completed: completed ?? this.completed,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      resource: resource ?? this.resource,
    );
  }

  @override
  String toString() {
    return 'VideoProgressModel(id: $id, resourceId: $resourceId, watchPercentage: $watchPercentage%, completed: $completed)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VideoProgressModel &&
        other.id == id &&
        other.userId == userId &&
        other.resourceId == resourceId;
  }

  @override
  int get hashCode {
    return id.hashCode ^ userId.hashCode ^ resourceId.hashCode;
  }
}
