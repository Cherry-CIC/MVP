class ProfileItem {
  final String username;
  final String location;
  final int reviewsCount;
  final int followersCount;
  final int followingCount;
  final double rating;
  final int awards; 
  final bool hasBuyerDiscounts;

  const ProfileItem(
      {required this.username, required this.location, required this.reviewsCount, required this.followersCount, required this.followingCount, required this.rating, required this.awards, required this.hasBuyerDiscounts});
}