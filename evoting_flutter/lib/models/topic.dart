class Topic {
  final int id;
  final String title;
  final String description;
  final bool isActive;
  final String createdAt;
  final String topicType;
  final String publicationStatus;
  final String disclaimer;
  final String? opensAt;
  final String? closesAt;
  final CivicPollSource? civicSource;

  Topic({
    required this.id,
    required this.title,
    required this.description,
    required this.isActive,
    required this.createdAt,
    required this.topicType,
    required this.publicationStatus,
    required this.disclaimer,
    this.opensAt,
    this.closesAt,
    this.civicSource,
  });

  factory Topic.fromJson(Map<String, dynamic> json) => Topic(
        id: json["id"],
        title: json["title"],
        description: json["description"] ?? "",
        isActive: json["is_active"],
        createdAt: json["created_at"],
        topicType: json["topic_type"] ?? "election",
        publicationStatus: json["publication_status"] ?? "published",
        disclaimer: json["disclaimer"] ?? "",
        opensAt: json["opens_at"],
        closesAt: json["closes_at"],
        civicSource: json["civic_source"] is Map<String, dynamic>
            ? CivicPollSource.fromJson(json["civic_source"])
            : null,
      );

  bool get isCivicPoll => topicType == "civic_poll";
}

class CivicPollSource {
  final String title;
  final String publisher;
  final String url;
  final int? segmentStartSeconds;
  final int? segmentEndSeconds;

  const CivicPollSource({
    required this.title,
    required this.publisher,
    required this.url,
    this.segmentStartSeconds,
    this.segmentEndSeconds,
  });

  factory CivicPollSource.fromJson(Map<String, dynamic> json) =>
      CivicPollSource(
        title: json["title"] ?? "",
        publisher: json["publisher"] ?? "",
        url: json["url"] ?? "",
        segmentStartSeconds: json["segment_start_seconds"],
        segmentEndSeconds: json["segment_end_seconds"],
      );
}
