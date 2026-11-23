import 'package:cherry_mvp/core/services/network/api_service.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'package:cherry_mvp/features/categories/category_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _Api implements ApiService {
  _Api(this.response);
  final Object response;

  @override
  Future<Result<T>> get<T>(String endpoint, {Map<String, dynamic>? queryParameters}) async =>
      Result.success(response as T);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('one incomplete category cannot hide valid categories or change their names', () async {
    final repository = CategoryRepository(
      _Api({
        'data': [
          _category('women', 'Women'),
          {'id': 'deleted-category'},
          null,
          _category('blank', ' '),
          _category('vinyl', 'Vinyl & Disk'),
        ],
      }),
    );
    final result = await repository.fetchCategories();
    expect(result.isSuccess, isTrue);
    expect(result.value!.map((category) => category.name), ['Women', 'Vinyl & Disk']);
  });

  test('supports a direct list and rejects an invalid response shape', () async {
    final direct = await CategoryRepository(_Api([_category('women', 'Women')])).fetchCategories();
    expect(direct.value!.single.id, 'women');
    final invalid = await CategoryRepository(_Api({'message': 'bad response'})).fetchCategories();
    expect(invalid.isSuccess, isFalse);
  });
}

Map<String, Object> _category(String id, String name) => {
  'id': id,
  'name': name,
  'imageUrl': 'https://example.com/category.png',
  'createdAt': '2026-01-01T00:00:00.000Z',
  'updatedAt': '2026-01-01T00:00:00.000Z',
};
