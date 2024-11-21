class User {
  final int id;
  final String phoneNumber;
  final String? name;
  final String? about;
  final String? profilePicUrl;
  final String? gender;
  final String? country;
  final DateTime? birthday;
  final String? bio;
  final String? motto;

  User({
    required this.id,
    required this.phoneNumber,
    this.name,
    this.about,
    this.profilePicUrl,
    this.gender,
    this.country,
    this.birthday,
    this.bio,
    this.motto,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      phoneNumber: json['phoneNumber'] ?? '',
      name: json['name'],
      about: json['about'],
      profilePicUrl: json['profilePicUrl'],
      gender: json['gender'],
      country: json['country'],
      birthday: json['birthday'] != null ? DateTime.tryParse(json['birthday']) : null,
      bio: json['bio'],
      motto: json['motto'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phoneNumber': phoneNumber,
      'name': name,
      'about': about,
      'profilePicUrl': profilePicUrl,
      'gender': gender,
      'country': country,
      'birthday': birthday?.toIso8601String(),
      'bio': bio,
      'motto': motto,
    };
  }
}
