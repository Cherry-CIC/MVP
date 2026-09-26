import 'dart:async';

import 'package:cherry_mvp/core/models/product.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'package:cherry_mvp/features/profile/public_user_profile_repository.dart';

class FakePublicProfileRepository implements IPublicUserProfileRepository {
  final FutureOr<Result<PublicUserProfilePage>> Function(String userId, String? cursor) respond;
  final calls = <({String userId, String? cursor})>[];

  FakePublicProfileRepository(this.respond);

  @override
  Future<Result<PublicUser>> fetchUser(String userId) async {
    final result = await respond(userId, null);
    if (!result.isSuccess || result.value == null) {
      return Result.failure(result.error, statusCode: result.statusCode);
    }
    return Result.success(result.value!.user);
  }

  @override
  Future<Result<PublicUserProfilePage>> fetchProfile(String userId, {int limit = 20, String? cursor}) async {
    calls.add((userId: userId, cursor: cursor));
    return await respond(userId, cursor);
  }
}

PublicUserProfilePage publicProfilePage({
  String userId = 'seller',
  String username = 'Alex',
  String? imageUrl,
  List<Product> products = const [],
  String? cursor,
}) => PublicUserProfilePage(
  user: PublicUser(id: userId, username: username, profileImageUrl: imageUrl),
  products: products,
  nextCursor: cursor,
  hasMore: cursor != null,
);

Product publicProfileProduct(String id, {String userId = 'seller'}) => Product(
  id: id,
  userId: userId,
  name: 'Listing $id',
  description: 'Pre-loved cotton shirt',
  quality: 'Good',
  productImages: const [],
  donation: 10,
  price: 10,
  securityFee: 1,
  likes: 0,
  number: 1,
  size: 'M',
  postageSizeId: 'small',
);
