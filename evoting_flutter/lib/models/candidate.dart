class Candidate {
  final int id;
  final int topicId;
  final String name;
  final String photo;
  final String bio;
  final int likes;
  final int dislikes;
  final int voteCount;
  final double votePercentage;

  Candidate({
    required this.id,
    required this.topicId,
    required this.name,
    required this.photo,
    required this.bio,
    this.likes = 0,
    this.dislikes = 0,
    this.voteCount = 0,
    this.votePercentage = 0.0,
  });

  factory Candidate.fromJson(Map<String, dynamic> json) => Candidate(
        id: json["id"],
        topicId: json["topic"] is int ? json["topic"] : (json["topic"]?["id"] ?? 0),
        name: json["name"] ?? "",
        photo: json["photo"] ?? "",
        bio: json["bio"] ?? "",
        likes: json['likes'] ?? 0,
        dislikes: json['dislikes'] ?? 0,
        voteCount: json['vote_count'] ?? 0,
        votePercentage: (json['vote_percentage'] as num?)?.toDouble() ?? 0.0,
      );
}

