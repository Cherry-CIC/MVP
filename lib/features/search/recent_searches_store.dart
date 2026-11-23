import 'package:shared_preferences/shared_preferences.dart';

/// Persists a user's recent item search queries locally on device.
class RecentSearchesStore {
  static const int maxEntries = 10;
  static const String _keyPrefix = 'recent_searches_v1_';

  final SharedPreferences? prefs;
  final String? Function() _currentUserIdProvider;
  final Map<String, List<String>> _memory = {};

  RecentSearchesStore({
    required this.prefs,
    String? Function()? currentUserIdProvider,
  }) : _currentUserIdProvider = currentUserIdProvider ?? (() => null);

  RecentSearchesStore.inMemory({
    String? Function()? currentUserIdProvider,
  }) : prefs = null,
       _currentUserIdProvider = currentUserIdProvider ?? (() => null);

  String get _storageKey {
    final uid = _currentUserIdProvider()?.trim();
    return '$_keyPrefix${(uid == null || uid.isEmpty) ? 'guest' : uid}';
  }

  static String normalize(String query) {
    return query.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  List<String> load() {
    final key = _storageKey;
    final preferences = prefs;
    if (preferences == null) {
      return List<String>.unmodifiable(_memory[key] ?? const []);
    }
    try {
      final raw = preferences.getStringList(key);
      if (raw == null) return const [];
      final cleaned = <String>[];
      final seen = <String>{};
      for (final item in raw) {
        final normalized = normalize(item);
        if (normalized.isEmpty) continue;
        if (seen.add(normalized.toLowerCase())) {
          cleaned.add(normalized);
          if (cleaned.length >= maxEntries) break;
        }
      }
      return List<String>.unmodifiable(cleaned);
    } catch (_) {
      return const [];
    }
  }

  Future<List<String>> add(String query) async {
    final normalized = normalize(query);
    if (normalized.isEmpty) return load();

    final updated = <String>[
      normalized,
      ...load().where((entry) => entry.toLowerCase() != normalized.toLowerCase()),
    ].take(maxEntries).toList();

    await _write(updated);
    return List<String>.unmodifiable(updated);
  }

  Future<List<String>> remove(String query) async {
    final normalized = normalize(query).toLowerCase();
    final updated = load()
        .where((entry) => entry.toLowerCase() != normalized)
        .toList();

    await _write(updated);
    return List<String>.unmodifiable(updated);
  }

  Future<void> clear() async {
    final key = _storageKey;
    final preferences = prefs;
    if (preferences == null) {
      _memory.remove(key);
      return;
    }
    try {
      await preferences.remove(key);
    } catch (_) {
      // Ignore storage failures so search stays responsive.
    }
  }

  Future<void> _write(List<String> entries) async {
    final key = _storageKey;
    final preferences = prefs;
    if (preferences == null) {
      _memory[key] = entries;
      return;
    }
    try {
      await preferences.setStringList(key, entries);
    } catch (_) {
      // Ignore storage failures so search stays responsive.
    }
  }
}
