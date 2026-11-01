import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:cherry_mvp/core/models/category.dart';
import 'package:cherry_mvp/core/router/nav_provider.dart';
import 'package:cherry_mvp/core/utils/utils.dart';
import 'package:cherry_mvp/features/categories/category_repository.dart';
import 'package:cherry_mvp/features/categories/category_view_model.dart';
import 'package:cherry_mvp/features/charity_page/charity_model.dart';
import 'package:cherry_mvp/features/charity_page/charity_repository.dart';
import 'package:cherry_mvp/features/charity_page/charity_viewmodel.dart';

class _CategoryRepository implements ICategoryRepository {
  _CategoryRepository(this.responses);

  final List<Future<Result<List<Category>>>> responses;
  int calls = 0;

  @override
  Future<Result<List<Category>>> fetchCategories() {
    calls++;
    return responses.removeAt(0);
  }
}

class _CharityRepository implements ICharityRepository {
  _CharityRepository(this.responses);

  final List<Future<Result<List<Charity>>>> responses;
  int calls = 0;

  @override
  Future<Result<List<Charity>>> fetchCharities() {
    calls++;
    return responses.removeAt(0);
  }
}

Category _category(String id) {
  final date = DateTime(2024);
  return Category(
    id: id,
    name: 'Women',
    imageUrl: '',
    createdAt: date,
    updatedAt: date,
  );
}

Charity _charity(String id) {
  final date = DateTime(2024);
  return Charity(
    id: id,
    name: 'Charity $id',
    imageUrl: '',
    createdAt: date,
    updatedAt: date,
  );
}

void main() {
  test('category requests are shared and successful data is reused', () async {
    final response = Completer<Result<List<Category>>>();
    final repository = _CategoryRepository([response.future]);
    final viewModel = CategoryViewModel(
      categoryRepository: repository,
      navigator: NavigationProvider(),
    );

    final first = viewModel.ensureCategoriesLoaded();
    final second = viewModel.ensureCategoriesLoaded();

    expect(repository.calls, 1);
    expect(viewModel.status.type, StatusType.loading);

    response.complete(Result.success([_category('1')]));
    await Future.wait([first, second]);

    expect(viewModel.status.type, StatusType.success);
    expect(viewModel.categories, hasLength(1));
    await viewModel.ensureCategoriesLoaded();
    expect(repository.calls, 1);
  });

  test('category retry is independent from charity loading', () async {
    final categoryResponse = Completer<Result<List<Category>>>();
    final retryResponse = Completer<Result<List<Category>>>();
    final categoryRepository = _CategoryRepository([
      categoryResponse.future,
      retryResponse.future,
    ]);
    final charityResponse = Completer<Result<List<Charity>>>();
    final charityRepository = _CharityRepository([charityResponse.future]);
    final categories = CategoryViewModel(
      categoryRepository: categoryRepository,
      navigator: NavigationProvider(),
    );
    final charities = CharityViewModel(
      charityRepository: charityRepository,
      navigator: NavigationProvider(),
    );

    final categoryRequest = categories.ensureCategoriesLoaded();
    final charityRequest = charities.ensureCharitiesLoaded();
    categoryResponse.complete(Result.failure('category failed'));
    charityResponse.complete(Result.success([_charity('1')]));
    await Future.wait([categoryRequest, charityRequest]);

    expect(categories.status.type, StatusType.failure);
    expect(charities.status.type, StatusType.success);
    expect(charityRepository.calls, 1);

    // A failed request can be retried through the same view-model without
    // affecting the successfully loaded charity dataset.
    final retry = categories.fetchCategories();
    expect(categoryRepository.calls, 2);
    retryResponse.complete(Result.success([_category('2')]));
    await retry;
    expect(categories.status.type, StatusType.success);
    expect(charities.charities, hasLength(1));
  });
}
