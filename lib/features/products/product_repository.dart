import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cherry_mvp/core/config/firestore_constants.dart';
import 'package:cherry_mvp/core/models/product.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'package:cherry_mvp/features/home/home_repository.dart';
import 'package:cherry_mvp/features/liked_items/models/liked_product_reference.dart';

class ProductRepository {
  ProductRepository({
    this.firebaseAuth,
    this.firebaseFirestore,
    this.homeRepository,
  });

  final FirebaseAuth? firebaseAuth;
  final FirebaseFirestore? firebaseFirestore;
  final IHomeRepository? homeRepository;

  FirebaseAuth get _auth => firebaseAuth ?? FirebaseAuth.instance;
  FirebaseFirestore get _firestore => firebaseFirestore ?? FirebaseFirestore.instance;

  Future<Result<void>> likeProduct(Product product) async {
    final productId = product.id;
    final validationError = _validateProductId(productId);
    if (validationError != null) {
      return Result.failure(validationError);
    }

    final uid = _currentUserId();
    if (uid == null) {
      return Result.failure('Please sign in to like products.');
    }

    try {
      await _likedProductsCollection(uid).doc(productId).set({
        FirestoreConstants.productId: productId,
        FirestoreConstants.likedAt: FieldValue.serverTimestamp(),
        FirestoreConstants.productSnapshot: _productSnapshot(product),
      }, SetOptions(merge: true));

      return Result.success(null);
    } catch (e) {
      return Result.failure('Unable to save this liked item. Please try again.');
    }
  }

  Future<Result<void>> unlikeProduct(String productId) async {
    final validationError = _validateProductId(productId);
    if (validationError != null) {
      return Result.failure(validationError);
    }

    final uid = _currentUserId();
    if (uid == null) {
      return Result.failure('Please sign in to update liked products.');
    }

    try {
      await _likedProductsCollection(uid).doc(productId).delete();
      return Result.success(null);
    } catch (e) {
      return Result.failure('Unable to remove this liked item. Please try again.');
    }
  }

  Future<Result<bool>> isProductLiked(String productId) async {
    final validationError = _validateProductId(productId);
    if (validationError != null) {
      return Result.failure(validationError);
    }

    final uid = _currentUserId();
    if (uid == null) {
      return Result.failure('Please sign in to view liked products.');
    }

    try {
      final document = await _likedProductsCollection(uid).doc(productId).get();
      return Result.success(document.exists);
    } catch (e) {
      return Result.failure('Unable to check this liked item. Please try again.');
    }
  }

  Future<Result<List<Product>>> fetchLikedProducts() async {
    final uid = _currentUserId();
    if (uid == null) {
      return Result.failure('Please sign in to view liked products.');
    }

    try {
      final likedSnapshot = await _likedProductsCollection(
        uid,
      ).orderBy(FirestoreConstants.likedAt, descending: true).get();
      final products = <Product>[];
      final missingProductIds = <String>[];
      final seenProductIds = <String>{};

      for (final likedDocument in likedSnapshot.docs) {
        final reference = LikedProductReference.tryParse(
          documentId: likedDocument.id,
          data: likedDocument.data(),
        );
        if (reference == null) {
          continue;
        }

        final product =
            _productFromLikedDocument(
              likedDocument.data(),
              reference.productId,
            ) ??
            await _fetchProduct(reference.productId);
        if (product != null) {
          if (seenProductIds.add(product.id)) {
            products.add(product);
          }
        } else {
          missingProductIds.add(reference.productId);
        }
      }

      final fallbackProducts = await _fetchProductsFromHomeFeed(missingProductIds);
      for (final productId in missingProductIds) {
        final product = fallbackProducts[productId];
        if (product != null && seenProductIds.add(product.id)) {
          products.add(product);
        }
      }

      return Result.success(products);
    } catch (e) {
      return Result.failure('We couldn’t load your liked items.');
    }
  }

  Map<String, dynamic> _productSnapshot(Product product) {
    return {
      'id': product.id,
      'userId': product.userId,
      'name': product.name,
      'description': product.description,
      'quality': product.quality,
      'product_images': product.productImages,
      'donation': product.donation,
      'price': product.price,
      'securityFee': product.securityFee,
      'likes': product.likes,
      'number': product.number,
      'size': product.size,
      'postageSize': product.postageSizeId,
      'categoryId': product.categoryId,
      'charityId': product.charityId,
      'createdAt': product.createdAt,
      'updatedAt': product.updatedAt,
      if (product.category != null) 'category': product.category!.toJson(),
      if (product.charity != null) 'charity': product.charity!.toJson(),
    };
  }

  Product? _productFromLikedDocument(Map<String, dynamic> data, String productId) {
    final snapshot = data[FirestoreConstants.productSnapshot];
    if (snapshot is! Map) {
      return null;
    }

    try {
      return Product.fromJson({
        ...Map<String, dynamic>.from(snapshot),
        'id': productId,
      });
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, Product>> _fetchProductsFromHomeFeed(
    List<String> productIds,
  ) async {
    final repository = homeRepository;
    if (repository == null || productIds.isEmpty) {
      return const <String, Product>{};
    }

    final requiredIds = productIds.toSet();
    final result = await repository.fetchProducts();
    if (!result.isSuccess || result.value == null) {
      return const <String, Product>{};
    }

    return {
      for (final product in result.value!)
        if (requiredIds.contains(product.id)) product.id: product,
    };
  }

  String? _currentUserId() {
    final uid = _auth.currentUser?.uid.trim();
    return uid == null || uid.isEmpty ? null : uid;
  }

  CollectionReference<Map<String, dynamic>> _likedProductsCollection(String uid) {
    return _firestore.collection(FirestoreConstants.users).doc(uid).collection(FirestoreConstants.likedProducts);
  }

  Future<Product?> _fetchProduct(String productId) async {
    try {
      final productDocument = await _firestore.collection(FirestoreConstants.products).doc(productId).get();

      if (!productDocument.exists) {
        return null;
      }

      final data = productDocument.data();
      if (data == null || _isHiddenProduct(data)) {
        return null;
      }

      return Product.fromJson({
        ...data,
        'id': productDocument.id,
      });
    } catch (e) {
      return null;
    }
  }

  bool _isHiddenProduct(Map<String, dynamic> data) {
    final status = data['status'];
    if (status is! String) {
      return false;
    }

    return const {'deleted', 'archived'}.contains(status.trim().toLowerCase());
  }

  String? _validateProductId(String productId) {
    if (productId.trim().isEmpty || productId.contains('/')) {
      return 'Invalid product ID.';
    }

    return null;
  }
}
