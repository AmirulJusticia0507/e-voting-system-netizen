class Vote {
  final int id;
  final int userId;
  final int topicId;
  final int candidateId;
  final String createdAt;

  Vote({
    required this.id,
    required this.userId,
    required this.topicId,
    required this.candidateId,
    required this.createdAt,
  });

  factory Vote.fromJson(Map<String, dynamic> json) => Vote(
        id: json["id"],
        userId: json["user"],
        topicId: json["topic"],
        candidateId: json["candidate"],
        createdAt: json["created_at"],
      );
}
