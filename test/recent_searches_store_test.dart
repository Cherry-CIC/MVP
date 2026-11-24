import 'package:cherry_mvp/features/search/recent_searches_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('normalizes, deduplicates case-insensitively, and caps at maxEntries', () async {
    final prefs = await SharedPreferences.getInstance();
    final store = RecentSearchesStore(prefs: prefs, currentUserIdProvider: () => 'user-1');

    expect(store.load(), isEmpty);
    await store.add('   ');
    expect(store.load(), isEmpty);

    for (var i = 1; i <= 12; i++) {
      await store.add('  item   $i  ');
    }

    final capped = store.load();
    expect(capped, hasLength(RecentSearchesStore.maxEntries));
    expect(capped.first, 'item 12');
    expect(capped.last, 'item 3');

    await store.add('ITEM 5');
    expect(store.load().first, 'ITEM 5');
    expect(store.load().where((e) => e.toLowerCase() == 'item 5'), hasLength(1));
  });

  test('isolates recent searches per signed-in user UID and guest', () async {
    final prefs = await SharedPreferences.getInstance();
    String? activeUid = 'alice';
    final store = RecentSearchesStore(
      prefs: prefs,
      currentUserIdProvider: () => activeUid,
    );

    await store.add('red coat');
    expect(store.load(), ['red coat']);

    activeUid = 'bob';
    expect(store.load(), isEmpty);
    await store.add('vintage boots');
    expect(store.load(), ['vintage boots']);

    activeUid = null;
    expect(store.load(), isEmpty);
    await store.add('guest hat');
    expect(store.load(), ['guest hat']);

    activeUid = 'alice';
    expect(store.load(), ['red coat']);
  });

  test('supports removing individual entries and clearing all', () async {
    final prefs = await SharedPreferences.getInstance();
    final store = RecentSearchesStore(prefs: prefs, currentUserIdProvider: () => 'user-1');

    await store.add('coat');
    await store.add('scarf');
    await store.add('boots');

    await store.remove('SCARF');
    expect(store.load(), ['boots', 'coat']);

    await store.clear();
    expect(store.load(), isEmpty);
  });
}
