class Candidate {
  final int id;
  final int topicId;
  final String name;
  final String photo;
  final String bio;
  final int likes;     // tambahkan
  final int dislikes;  // tambahkan

  Candidate({
    required this.id,
    required this.topicId,
    required this.name,
    required this.photo,
    required this.bio,
    this.likes = 0,
    this.dislikes = 0,
  });

  factory Candidate.fromJson(Map<String, dynamic> json) => Candidate(
        id: json["id"],
        topicId: json["topic"],
        name: json["name"],
        photo: json["photo"],
        bio: json["bio"] ?? "",
        likes: json['likes'] ?? 0,        // parsing dari backend
        dislikes: json['dislikes'] ?? 0,  // parsing dari backend
      );
}
