import 'package:cherry_mvp/core/models/product.dart';
import 'package:flutter/foundation.dart';

/// Details a buyer must review again if they change before payment.
/// Likes and timestamps are deliberately excluded.
bool sameListingDetails(Product a, Product b) =>
    a.id == b.id &&
    a.userId == b.userId &&
    a.name == b.name &&
    a.description == b.description &&
    listEquals(a.productImages, b.productImages) &&
    a.categoryId == b.categoryId &&
    a.charityId == b.charityId &&
    a.quality == b.quality &&
    a.size == b.size &&
    a.price == b.price &&
    a.donation == b.donation &&
    a.securityFee == b.securityFee &&
    a.postageSizeId == b.postageSizeId &&
    a.number == b.number &&
    a.status == b.status &&
    a.editVersion == b.editVersion;
