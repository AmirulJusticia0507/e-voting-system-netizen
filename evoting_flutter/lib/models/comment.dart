class Comment {
  final int id;
  final int? userId;
  final String? username;
  final int topicId;
  final String text;
  final int likes;
  final int dislikes;
  final bool isReported;
  final String createdAt;

  Comment({
    required this.id,
    this.userId,
    this.username,
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
        username: json["username"],
        topicId: json["topic"],
        text: json["text"] ?? "",
        likes: json["likes"] ?? 0,
        dislikes: json["dislikes"] ?? 0,
        isReported: json["is_reported"] ?? false,
        createdAt: json["created_at"] ?? "",
      );
}

