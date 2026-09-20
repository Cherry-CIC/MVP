import 'package:cherry_mvp/core/models/product.dart';

/// The complete allowlist of account information shown on a public profile.
class PublicUser {
  final String id;
  final String username;
  final String? profileImageUrl;

  const PublicUser({
    required this.id,
    required this.username,
    this.profileImageUrl,
  });
}

class PublicUserProfilePage {
  final PublicUser user;
  final List<Product> products;
  final String? nextCursor;
  final bool hasMore;

  const PublicUserProfilePage({
    required this.user,
    required this.products,
    required this.nextCursor,
    required this.hasMore,
  });
}
