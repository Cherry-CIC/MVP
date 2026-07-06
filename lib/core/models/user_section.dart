class UserInformation {
  final String username;
  final String location;
  final int reviewsCount;
  final int followersCount;
  final int followingCount;
  final double rating;
  final int awards;

  final bool hasBuyerDiscounts;

  UserInformation(
      {required this.username,
      required this.location,
      required this.reviewsCount,
      required this.followersCount,
      required this.followingCount,
      required this.rating,
      required this.awards,
      required this.hasBuyerDiscounts});

  // Optional: fromJson for deserialization
  factory UserInformation.fromJson(Map<String, dynamic> json) {
    return UserInformation(
      username: json['username'],
      location: json['location'],
      reviewsCount: json['reviewsCount'],
      followersCount: json['followersCount'],
      followingCount: json['followingCount'],
      rating: (json['rating'] as num).toDouble(),
      awards: json['awards'],
      hasBuyerDiscounts: json['hasBuyerDiscounts'],
    );
  }

  // Optional: toJson for serialization
  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'location': location,
      'reviewsCount': reviewsCount,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'rating': rating,
      'awards': awards,
      'hasBuyerDiscounts': hasBuyerDiscounts,
    };
  }
}
