class User {
  final int id;
  final String phoneNumber;
  final String? otpCode;
  final String? photo;
  final bool isVerified;
  final String createdAt;

  User({
    required this.id,
    required this.phoneNumber,
    this.otpCode,
    this.photo,
    required this.isVerified,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json["id"],
        phoneNumber: json["phone_number"],
        otpCode: json["otp_code"],
        photo: json["photo"],
        isVerified: json["is_verified"],
        createdAt: json["created_at"],
      );
}
