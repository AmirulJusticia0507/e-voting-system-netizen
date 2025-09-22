class Comment {
  final int id;
  final int userId;
  final int topicId;
  final String text;
  final int likes;
  final int dislikes;
  final bool isReported;
  final String createdAt;

  Comment({
    required this.id,
    required this.userId,
    required this.topicId,
    required this.text,
    required this.likes,
    required this.dislikes,
    required this.isReported,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) => Comment(
        id: json["id"],
        userId: json["user"],
        topicId: json["topic"],
        text: json["text"],
        likes: json["likes"],
        dislikes: json["dislikes"],
        isReported: json["is_reported"],
        createdAt: json["created_at"],
      );
}
