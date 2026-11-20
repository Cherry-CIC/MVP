import 'dart:async';

import 'package:cherry_mvp/core/models/model.dart';
import 'package:cherry_mvp/core/utils/utils.dart';
import 'package:cherry_mvp/features/home/home_repository.dart';
import 'package:cherry_mvp/features/home/home_viewmodel.dart';
import 'package:cherry_mvp/features/products/deleted_listings.dart';
import 'package:flutter_test/flutter_test.dart';

class _Repository implements IHomeRepository {
  final responses = <Future<Result<ProductPage>>>[];
  final requests = <({String? search, String? categoryId, String? cursor})>[];

  @override
  Future<Result<ProductPage>> fetchProducts({
    int limit = 20,
    String? cursor,
    String? search,
    String? categoryId,
  }) {
    requests.add((search: search, categoryId: categoryId, cursor: cursor));
    return responses.removeAt(0);
  }
}

final _women = _category('women', 'Women');
final _men = _category('men', 'Men');

void main() {
  late _Repository repository;
  late HomeViewModel model;

  setUp(() {
    repository = _Repository();
    model = HomeViewModel(homeRepository: repository);
  });
  tearDown(() => model.dispose());

  testWidgets('category browsing, typing and backspace retain the category', (tester) async {
    repository.responses.addAll([
      Future.value(_page(['category'])),
      Future.value(_page(['matching'])),
      Future.value(_page(['category'])),
    ]);
    await model.selectSearchCategory(_women);
    expect(model.hasActiveSearch, isTrue);
    expect(repository.requests.single, (search: '', categoryId: 'women', cursor: null));

    model.updateSearchText(' coat ');
    await tester.pump(HomeViewModel.searchDebounceDuration);
    expect(repository.requests.last.search, 'coat');
    expect(repository.requests.last.categoryId, 'women');
    expect(model.searchProducts.single.id, 'matching');

    model.updateSearchText('');
    await tester.pump(HomeViewModel.searchDebounceDuration);
    expect(model.searchCategory, _women);
    expect(model.searchProducts.single.id, 'category');
    model.clearSearch();
    expect(model.hasActiveSearch, isFalse);
    expect(model.searchCategory, isNull);
    expect(model.searchProducts, isEmpty);
  });

  test('a late response cannot replace a newly selected category', () async {
    final old = Completer<Result<ProductPage>>();
    repository.responses.addAll([
      old.future,
      Future.value(_page(['men'])),
    ]);
    final previous = model.selectSearchCategory(_women);
    await model.selectSearchCategory(_men);
    old.complete(_page(['women'], nextCursor: 'old'));
    await previous;
    expect(model.searchCategory, _men);
    expect(model.searchProducts.single.id, 'men');
    expect(model.searchHasMore, isFalse);
  });

  testWidgets('changing text invalidates pagination before debounce finishes', (tester) async {
    final oldPage = Completer<Result<ProductPage>>();
    repository.responses.addAll([
      Future.value(_page(['first'], nextCursor: 'next')),
      oldPage.future,
      Future.value(_page(['new'])),
    ]);
    await model.selectSearchCategory(_women);
    final pagination = model.loadMoreSearchProducts();
    model.updateSearchText('coat');
    oldPage.complete(_page(['old'], nextCursor: 'old-next'));
    await pagination;
    expect(model.searchProducts, isEmpty);
    expect(model.isSearchLoading, isTrue);
    await tester.pump(HomeViewModel.searchDebounceDuration);
    expect(model.searchProducts.single.id, 'new');
  });

  testWidgets('unchanged normalised text does not repeat a request and retry is explicit', (tester) async {
    repository.responses.addAll([
      Future.value(Result.failure('offline')),
      Future.value(_page(['retried'])),
    ]);
    model.updateSearchText('coat');
    await tester.pump(HomeViewModel.searchDebounceDuration);
    model.updateSearchText(' coat ');
    await tester.pump(HomeViewModel.searchDebounceDuration);
    expect(repository.requests, hasLength(1));
    expect(model.searchStatus.type, StatusType.failure);
    await model.retrySearch();
    expect(repository.requests, hasLength(2));
    expect(model.searchProducts.single.id, 'retried');
  });

  test('empty visible page with continuation can load more and retry', () async {
    final deleted = DeletedListings()..add('deleted');
    model.dispose();
    model = HomeViewModel(homeRepository: repository, deletedListings: deleted);
    repository.responses.addAll([
      Future.value(_page(['deleted'], nextCursor: 'next')),
      Future.value(Result.failure('offline')),
      Future.value(_page(['visible'])),
    ]);
    await model.selectSearchCategory(_women);
    expect(model.searchProducts, isEmpty);
    expect(model.isSearchEmpty, isFalse);
    expect(model.searchHasMore, isTrue);
    await model.loadMoreSearchProducts();
    expect(model.searchLoadMoreError, isNotEmpty);
    expect(model.searchNextCursor, 'next');
    await model.loadMoreSearchProducts();
    expect(model.searchProducts.single.id, 'visible');
    expect(model.searchLoadMoreError, isNull);
    expect(repository.requests.skip(1).map((request) => request.categoryId), everyElement('women'));
  });

  for (final isEdit in [false, true]) {
    test('category-only search refreshes after listing ${isEdit ? 'edit' : 'deletion'}', () async {
      repository.responses.addAll([
        Future.value(_page(['old'])),
        Future.value(_page(['home'])),
        Future.value(_page(['fresh'])),
      ]);
      await model.selectSearchCategory(_women);
      await (isEdit ? model.refreshAfterListingEdit() : model.refreshAfterListingDeletion());
      expect(model.searchCategory, _women);
      expect(repository.requests.last.categoryId, 'women');
      expect(repository.requests.last.search, '');
      expect(model.searchProducts.single.id, 'fresh');
    });
  }

  test('clearing a selected category retains text and discards the old cursor', () async {
    repository.responses.addAll([
      Future.value(_page(['category'], nextCursor: 'old')),
      Future.value(_page(['global'])),
    ]);
    await model.selectSearchCategory(_women);
    model.updateSearchText('coat');
    await model.selectSearchCategory(null);
    expect(repository.requests.last, (search: 'coat', categoryId: null, cursor: null));
    expect(model.searchProducts.single.id, 'global');
  });

  test('submitSearch records normalized query and executes search immediately', () async {
    repository.responses.add(Future.value(_page(['coat-1'])));

    await model.submitSearch('  Red   coat ');
    expect(model.recentSearches, ['Red coat']);
    expect(repository.requests.single, (search: 'Red coat', categoryId: null, cursor: null));
    expect(model.searchProducts.single.id, 'coat-1');

    await model.removeRecentSearch('red coat');
    expect(model.recentSearches, isEmpty);
  });
}

Category _category(String id, String name) => Category(
  id: id,
  name: name,
  imageUrl: '',
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

Result<ProductPage> _page(List<String> ids, {String? nextCursor}) => Result.success(
  ProductPage(
    products: ids
        .map(
          (id) => Product(
            id: id,
            name: id,
            description: '',
            quality: 'GOOD',
            productImages: const [],
            donation: 5,
            price: 5,
            securityFee: 1,
            likes: 0,
            number: 1,
            size: 'M',
            postageSizeId: 'small',
          ),
        )
        .toList(),
    limit: 20,
    nextCursor: nextCursor,
    hasMore: nextCursor != null,
  ),
);
