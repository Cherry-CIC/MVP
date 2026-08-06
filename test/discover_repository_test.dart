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

  test('includes each newly supplied charity exactly once', () {
    final charityNames = repository.fetchCharities().map((charity) => charity.charityName).toList();
    final expectedNames = {
      "Alzheimer's Society",
      'World Animal Protection',
      'Leicester Animal Aid',
      'British Red Cross',
      'UNICEF',
      'Save the Children',
      'Prostate Cancer Research',
      'Macmillan Cancer Support',
      'RSPCA',
      'The Cat Welfare Group',
    };

    expect(charityNames, containsAll(expectedNames));
    for (final name in expectedNames) {
      expect(charityNames.where((charityName) => charityName == name), hasLength(1));
    }
  });

  test('filters charities using their Discover category tag', () {
    final smallerCharities = repository.fetchCharities(tag: 'smaller-charities');
    final localCharities = repository.fetchCharities(tag: 'local');

    expect(
      smallerCharities.map((charity) => charity.charityName),
      containsAll(<String>[
        'West London NHS Charity',
        'New College Worcester',
        'Leicester Animal Aid',
        'The Cat Welfare Group',
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
      "Alzheimer's Society",
      'World Animal Protection',
      'Leicester Animal Aid',
      'British Red Cross',
      'UNICEF',
      'Save the Children',
      'Prostate Cancer Research',
      'Macmillan Cancer Support',
      'RSPCA',
      'The Cat Welfare Group',
    ]) {
      expect(charitiesByName[charityName]!.charityLogo, isNotEmpty);
    }

    expect(
      charitiesByName['The Cat Welfare Group']!.logoUsesDarkBackground,
      isTrue,
    );
  });
}
