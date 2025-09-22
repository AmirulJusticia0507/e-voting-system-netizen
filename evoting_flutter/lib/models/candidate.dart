class Candidate {
  final int id;
  final int topicId;
  final String name;
  final String photo;
  final String bio;

  Candidate({
    required this.id,
    required this.topicId,
    required this.name,
    required this.photo,
    required this.bio,
  });

  factory Candidate.fromJson(Map<String, dynamic> json) => Candidate(
        id: json["id"],
        topicId: json["topic"],
        name: json["name"],
        photo: json["photo"],
        bio: json["bio"] ?? "",
      );
}
