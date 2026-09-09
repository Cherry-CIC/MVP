import 'dart:async';

import 'package:cherry_mvp/core/models/category.dart';
import 'package:cherry_mvp/core/models/product.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'package:cherry_mvp/features/categories/category_repository.dart';
import 'package:cherry_mvp/features/charity_page/charity_model.dart';
import 'package:cherry_mvp/features/charity_page/charity_repository.dart';
import 'package:cherry_mvp/features/donation/donation_repository.dart';
import 'package:cherry_mvp/features/donation/models/donation_model.dart';
import 'package:cherry_mvp/features/donation/models/postage_size_info.dart';
import 'package:image_picker/image_picker.dart';

class ControlledDonationRepository implements IDonationRepository {
  final requests = <DonationRequest>[];
  final submissions = <Completer<Result<DonationResponse>>>[];
  final postageLoads = <Completer<Result<List<PostageSizeInfo>>>>[];

  @override
  Future<Result<DonationResponse>> submitDonation(DonationRequest request) {
    requests.add(request);
    final pending = Completer<Result<DonationResponse>>();
    submissions.add(pending);
    return pending.future;
  }

  @override
  Future<Result<List<PostageSizeInfo>>> fetchPostageSizes() {
    final pending = Completer<Result<List<PostageSizeInfo>>>();
    postageLoads.add(pending);
    return pending.future;
  }
}

final testCategory = Category(
  id: 'category-id',
  name: 'Women',
  imageUrl: '',
  createdAt: DateTime(2025),
  updatedAt: DateTime(2025),
);
final testCharity = Charity(
  id: 'charity-id',
  name: 'Test charity',
  imageUrl: '',
  createdAt: DateTime(2025),
  updatedAt: DateTime(2025),
);
final testPostage = PostageSizeInfo(
  id: 'postage-small',
  type: 'inpost',
  size: PostageSize.small,
  description: 'Small parcel',
  weight: 500,
);
final otherPostage = PostageSizeInfo(
  id: 'postage-large',
  type: 'inpost',
  size: PostageSize.large,
  description: 'Large parcel',
  weight: 2000,
);

class DonationCategoriesStub implements ICategoryRepository {
  @override
  Future<Result<List<Category>>> fetchCategories() async => Result.success([testCategory]);
}

class DonationCharitiesStub implements ICharityRepository {
  @override
  Future<Result<List<Charity>>> fetchCharities() async => Result.success([testCharity]);
}

DonationRequest testDonationRequest({List<XFile>? images, List<String>? urls}) => DonationRequest(
  name: 'Wool jumper',
  description: 'Warm wool jumper',
  categoryId: testCategory.id,
  charityId: testCharity.id,
  quality: 'GOOD',
  size: 'Medium',
  postageSizeId: testPostage.id,
  donation: 12,
  price: 12,
  localImages: images,
  productImages: urls,
);

DonationResponse testDonationResponse() => DonationResponse(
  success: true,
  message: 'Created',
  data: Product(
    id: 'created-listing',
    name: 'Wool jumper',
    description: 'Warm wool jumper',
    quality: 'GOOD',
    productImages: const [],
    donation: 12,
    price: 12,
    securityFee: 1,
    likes: 0,
    number: 10,
    size: 'Medium',
    postageSizeId: testPostage.id,
  ),
);

final otherCategory = Category(
  id: 'other-category',
  name: 'Men',
  imageUrl: '',
  createdAt: DateTime(2025),
  updatedAt: DateTime(2025),
);
final otherCharity = Charity(
  id: 'other-charity',
  name: 'Another charity',
  imageUrl: '',
  createdAt: DateTime(2025),
  updatedAt: DateTime(2025),
);
