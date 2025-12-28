class DailyChallengeProgressModel {
  final String id;
  final String userId;
  final String challengeId;
  final bool userAnswer;
  final bool isCorrect;
  final int scoreAwarded;
  final DateTime completedAt;
  final DateTime createdAt;
  final Map<String, dynamic>? challenge; // Challenge data if included

  DailyChallengeProgressModel({
    required this.id,
    required this.userId,
    required this.challengeId,
    required this.userAnswer,
    required this.isCorrect,
    required this.scoreAwarded,
    required this.completedAt,
    required this.createdAt,
    this.challenge,
  });

  factory DailyChallengeProgressModel.fromJson(Map<String, dynamic> json) {
    return DailyChallengeProgressModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      challengeId: json['challenge_id'] as String,
      userAnswer: json['user_answer'] as bool,
      isCorrect: json['is_correct'] as bool,
      scoreAwarded: json['score_awarded'] as int,
      completedAt: DateTime.parse(json['completed_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      challenge: json['daily_challenges'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'challenge_id': challengeId,
      'user_answer': userAnswer,
      'is_correct': isCorrect,
      'score_awarded': scoreAwarded,
      'completed_at': completedAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      if (challenge != null) 'daily_challenges': challenge,
    };
  }

  DailyChallengeProgressModel copyWith({
    String? id,
    String? userId,
    String? challengeId,
    bool? userAnswer,
    bool? isCorrect,
    int? scoreAwarded,
    DateTime? completedAt,
    DateTime? createdAt,
    Map<String, dynamic>? challenge,
  }) {
    return DailyChallengeProgressModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      challengeId: challengeId ?? this.challengeId,
      userAnswer: userAnswer ?? this.userAnswer,
      isCorrect: isCorrect ?? this.isCorrect,
      scoreAwarded: scoreAwarded ?? this.scoreAwarded,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      challenge: challenge ?? this.challenge,
    );
  }

  @override
  String toString() {
    return 'DailyChallengeProgressModel(id: $id, challengeId: $challengeId, isCorrect: $isCorrect, score: $scoreAwarded)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DailyChallengeProgressModel &&
        other.id == id &&
        other.userId == userId &&
        other.challengeId == challengeId;
  }

  @override
  int get hashCode {
    return id.hashCode ^ userId.hashCode ^ challengeId.hashCode;
  }
}
