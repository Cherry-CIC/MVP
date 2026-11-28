import 'package:cherry_mvp/features/charity_page/charity_model.dart';
import 'package:cherry_mvp/features/charity_page/charity_profile_args.dart';
import 'package:cherry_mvp/features/discover/discover_repository.dart';

/// A charity that matched a search query, ready to display and open.
class CharitySearchResult {
  const CharitySearchResult({
    required this.name,
    required this.profileArgs,
    this.logoPath,
    this.usesDarkLogoBackground = false,
  });

  final String name;

  /// Image shown beside the charity name (an asset path or an https URL).
  final String? logoPath;
  final bool usesDarkLogoBackground;

  /// Validated payload for opening the charity's profile page.
  final CharityProfileArgs profileArgs;
}

/// Finds charities by name so search can show them next to items.
///
/// Matching happens entirely in memory on plain strings (never as a regular
/// expression), so user input cannot cause errors or extra network requests.
class CharitySearch {
  const CharitySearch({required this.discoverRepository});

  static const int maxResults = 5;
  static const int minQueryLength = 2;

  final DiscoverRepository discoverRepository;

  /// Lower-cases [value] and removes everything except letters and digits, so
  /// "Water Aid", "water-aid" and "WaterAid" (or "Alzheimer's" and
  /// "alzheimers") all compare as equal.
  static String normalise(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^\p{L}\p{N}]', unicode: true), '');
  }

  /// Returns up to [limit] charities whose name contains [query].
  ///
  /// Charities from the Discover catalogue are searched first, followed by
  /// any extra [apiCharities] loaded from the backend. A charity that appears
  /// in both (same id, or same normalised name) is only returned once.
  List<CharitySearchResult> search(
    String query, {
    List<Charity> apiCharities = const [],
    int limit = maxResults,
  }) {
    final needle = normalise(query);
    if (needle.length < minQueryLength || limit <= 0) return const [];

    final candidates = <_Candidate>[];
    final seenIds = <String>{};
    final seenNames = <String>{};

    bool isNew(String? id, String normalisedName) {
      final safeId = CharityProfileArgs.safeIdentifier(id);
      if (normalisedName.isEmpty) return false;
      if (safeId != null && seenIds.contains(safeId)) return false;
      if (seenNames.contains(normalisedName)) return false;
      if (safeId != null) seenIds.add(safeId);
      seenNames.add(normalisedName);
      return true;
    }

    for (final charity in discoverRepository.fetchCharities()) {
      final normalisedName = normalise(charity.charityName);
      if (!isNew(charity.id, normalisedName)) continue;
      candidates.add(
        _Candidate(
          normalisedName: normalisedName,
          result: CharitySearchResult(
            name: charity.charityName,
            logoPath: charity.charityLogo,
            usesDarkLogoBackground: charity.logoUsesDarkBackground,
            profileArgs: CharityProfileArgs(
              charityId: charity.id,
              charityName: charity.charityName,
              charityImageUrl: charity.charityLogo,
            ),
          ),
        ),
      );
    }

    for (final charity in apiCharities) {
      final normalisedName = normalise(charity.name);
      if (!isNew(charity.id, normalisedName)) continue;
      final imageUrl = charity.imageUrl.trim();
      candidates.add(
        _Candidate(
          normalisedName: normalisedName,
          result: CharitySearchResult(
            name: charity.name,
            logoPath: imageUrl.isEmpty ? null : imageUrl,
            profileArgs: CharityProfileArgs(
              charity: charity,
              charityId: charity.id,
              charityName: charity.name,
              charityImageUrl: imageUrl.isEmpty ? null : imageUrl,
            ),
          ),
        ),
      );
    }

    final matches = <_Candidate>[
      for (final candidate in candidates)
        if (candidate.normalisedName.contains(needle)) candidate,
    ];

    // Best matches first: exact name, then names starting with the query, then
    // names that merely contain it. Dart's sort is not guaranteed stable, so
    // ties fall back to alphabetical order to keep results predictable.
    int rank(_Candidate candidate) {
      if (candidate.normalisedName == needle) return 0;
      if (candidate.normalisedName.startsWith(needle)) return 1;
      return 2;
    }

    matches.sort((a, b) {
      final byRank = rank(a).compareTo(rank(b));
      if (byRank != 0) return byRank;
      return a.normalisedName.compareTo(b.normalisedName);
    });

    return List<CharitySearchResult>.unmodifiable(
      matches.take(limit).map((candidate) => candidate.result),
    );
  }
}

class _Candidate {
  const _Candidate({required this.normalisedName, required this.result});

  final String normalisedName;
  final CharitySearchResult result;
}
