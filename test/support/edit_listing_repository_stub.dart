import 'package:cherry_mvp/core/models/product.dart';
import 'package:cherry_mvp/features/products/edit_listing/edit_listing_repository.dart';
import 'package:flutter_test/flutter_test.dart';

export 'package:cherry_mvp/features/products/edit_listing/edit_listing_repository.dart';

/// Supplies the product page's editor dependency without making API requests.
class EditListingRepositoryStub extends Fake implements IEditListingRepository {
  @override
  bool canEdit(Product product) => product.number > 0 && (product.status == 'active' || product.status == 'unlisted');
}
