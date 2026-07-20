import 'package:cherry_mvp/features/discover/discover_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final repository = DiscoverRepository();

  test('includes the six new charities in the local Discover feed', () {
    final charityNames = repository.fetchCharities().map((charity) => charity.charityName).toSet();

    expect(
      charityNames,
      containsAll({
        'Maudsley Charity',
        'British Heart Foundation',
        'West London NHS Charity',
        'Disaster Aid UK & Ireland',
        'New College Worcester',
        'Groundwork',
      }),
    );
  });

  test('filters charities using their Discover category tag', () {
    final smallerCharities = repository.fetchCharities(tag: 'smaller-charities');
    final localCharities = repository.fetchCharities(tag: 'local');

    expect(
      smallerCharities.map((charity) => charity.charityName),
      containsAll(<String>[
        'West London NHS Charity',
        'New College Worcester',
      ]),
    );
    expect(
      localCharities.map((charity) => charity.charityName),
      contains('West London NHS Charity'),
    );
  });

  test('uses the supplied official logos where available', () {
    final charitiesByName = {
      for (final charity in repository.fetchCharities()) charity.charityName: charity,
    };

    for (final charityName in [
      'Maudsley Charity',
      'British Heart Foundation',
      'Disaster Aid UK & Ireland',
      'Groundwork',
    ]) {
      expect(charitiesByName[charityName]!.charityLogo, isNotEmpty);
    }
  });
}
