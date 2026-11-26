import 'package:cherry_mvp/features/charity_page/charity_model.dart';
import 'package:cherry_mvp/features/charity_page/charity_profile_args.dart';
import 'package:cherry_mvp/features/discover/discover_repository.dart';
import 'package:cherry_mvp/features/search/charity_search.dart';
import 'package:flutter_test/flutter_test.dart';

Charity _apiCharity(String id, String name, {String imageUrl = 'https://example.com/logo.png'}) => Charity(
  id: id,
  name: name,
  imageUrl: imageUrl,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

List<String> _names(List<CharitySearchResult> results) => [for (final result in results) result.name];

void main() {
  late CharitySearch search;

  setUp(() => search = CharitySearch(discoverRepository: DiscoverRepository()));

  group('normalise', () {
    test('ignores case, spaces, hyphens, apostrophes and ampersands', () {
      expect(CharitySearch.normalise('Water Aid'), 'wateraid');
      expect(CharitySearch.normalise('WATER-AID'), 'wateraid');
      expect(CharitySearch.normalise("Alzheimer's"), 'alzheimers');
      expect(CharitySearch.normalise('Alzheimer\u2019s'), 'alzheimers');
      expect(CharitySearch.normalise('Disaster Aid UK & Ireland'), 'disasteraidukireland');
    });

    test('keeps letters and digits, including non-English letters', () {
      expect(CharitySearch.normalise('Café 24'), 'café24');
    });
  });

  group('matching', () {
    test('"water aid" finds WaterAid, however it is typed', () {
      for (final query in ['water aid', 'wateraid', 'WATER-AID', '  Water   Aid  ', 'water']) {
        expect(_names(search.search(query)), contains('WaterAid'), reason: 'query: "$query"');
      }
    });

    test('ignores apostrophes in names and queries', () {
      expect(_names(search.search('alzheimers')), contains("Alzheimer's Society"));
      expect(_names(search.search("alzheimer's")), contains("Alzheimer's Society"));
    });

    test('matches names containing ampersands', () {
      expect(_names(search.search('disaster aid uk ireland')), contains('Disaster Aid UK & Ireland'));
    });

    test('matches the middle of a name', () {
      expect(_names(search.search('heart')), contains('British Heart Foundation'));
    });

    test('returns nothing for empty, too-short, symbol-only or unknown queries', () {
      for (final query in ['', '   ', 'm', ' w ', '---', '&&', 'zzzzzzzz']) {
        expect(search.search(query), isEmpty, reason: 'query: "$query"');
      }
    });

    test('treats regular-expression characters as plain text', () {
      for (final query in ['(*[\\', '.*', r'$^', '[a-z]+', '(?<=a)', r'\p{L}']) {
        expect(() => search.search(query), returnsNormally, reason: 'query: "$query"');
        expect(search.search(query), isEmpty, reason: 'query: "$query"');
      }
    });

    test('opens the profile with the catalogue id and name', () {
      final result = search.search('water aid').firstWhere((r) => r.name == 'WaterAid');
      expect(result.profileArgs.charityId, 'ca6tjKqCRurG0hB49Dcp');
      expect(result.profileArgs.charityName, 'WaterAid');
      expect(result.logoPath, isNotEmpty);
    });
  });

  group('ranking and limits', () {
    test('exact name beats prefix, which beats contains', () {
      final results = search.search(
        'aid',
        limit: 20,
        apiCharities: [_apiCharity('x1', 'Aid Now'), _apiCharity('x2', 'Aid'), _apiCharity('x3', 'First Aid Trust')],
      );
      final names = _names(results);
      expect(names.first, 'Aid');
      expect(names.indexOf('Aid Now'), lessThan(names.indexOf('First Aid Trust')));
      expect(names.indexOf('Aid Now'), lessThan(names.indexOf('WaterAid')));
    });

    test('caps results at the default maximum and honours a custom limit', () {
      expect(search.search('an').length, lessThanOrEqualTo(CharitySearch.maxResults));
      expect(search.search('an', limit: 2), hasLength(2));
      expect(search.search('an', limit: 0), isEmpty);
    });

    test('results are stable between calls', () {
      expect(_names(search.search('an')), _names(search.search('an')));
    });
  });

  group('backend charities', () {
    test('adds charities that are not in the Discover catalogue', () {
      final results = search.search('home start', apiCharities: [_apiCharity('QVAfoZuZfIlEoQOcsZ8F', 'Home Start')]);
      expect(_names(results), ['Home Start']);
      expect(results.single.profileArgs.charity?.id, 'QVAfoZuZfIlEoQOcsZ8F');
      expect(results.single.logoPath, 'https://example.com/logo.png');
    });

    test('does not repeat a charity that has the same id in both sources', () {
      final results = search.search('water', apiCharities: [_apiCharity('ca6tjKqCRurG0hB49Dcp', 'Water Aid')]);
      expect(_names(results), ['WaterAid']);
    });

    test('does not repeat a charity that has the same name under another id', () {
      final results = search.search('wateraid', apiCharities: [_apiCharity('different-id', 'Water Aid')]);
      expect(_names(results), ['WaterAid']);
    });

    test('leaves out the image when the backend has none', () {
      final results = search.search('quietcharity', apiCharities: [_apiCharity('q1', 'Quiet Charity', imageUrl: '  ')]);
      expect(results.single.logoPath, isNull);
      expect(results.single.profileArgs.charityImageUrl, isNull);
    });

    test('ignores backend charities with blank names', () {
      expect(search.search('zz', apiCharities: [_apiCharity('b1', '   '), _apiCharity('b2', '')]), isEmpty);
    });

    test('an unsafe backend id never reaches navigation', () {
      final results = search.search('sneaky', apiCharities: [_apiCharity('../../admin', 'Sneaky Charity')]);
      expect(results, hasLength(1));
      final args = CharityProfileArgs.fromRouteArgument(results.single.profileArgs);
      expect(args, isNotNull);
      expect(args!.charityId, isNull);
      expect(args.charityName, 'Sneaky Charity');
    });
  });
}
