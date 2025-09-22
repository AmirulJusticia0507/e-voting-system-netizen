class Topic {
  final int id;
  final String title;
  final String description;
  final bool isActive;
  final String createdAt;

  Topic({
    required this.id,
    required this.title,
    required this.description,
    required this.isActive,
    required this.createdAt,
  });

  factory Topic.fromJson(Map<String, dynamic> json) => Topic(
        id: json["id"],
        title: json["title"],
        description: json["description"] ?? "",
        isActive: json["is_active"],
        createdAt: json["created_at"],
      );
}
