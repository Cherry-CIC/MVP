class Inpost {
  final String id;
  final String name;
  final String address;
  final String postcode;
  final String city;
  final String country;
  final String lat;
  final String long;

  const Inpost({
    required this.id,
    required this.name,
    required this.address,
    required this.postcode,
    required this.city,
    required this.country,
    required this.lat,
    required this.long,
  });
}

class InpostSearchResult {
  final Inpost inpost;
  final int distanceMetres;

  InpostSearchResult({
    required this.inpost,
    required this.distanceMetres,
  });

  String get displayDistance {
    if (distanceMetres < 1000) return '$distanceMetres m';
    final km = distanceMetres / 1000;
    return '${km.toStringAsFixed(km % 1 == 0 ? 0 : 1)} km';
  }

  String get concatenatedAddress {
    return [
      inpost.address,
      inpost.city,
      inpost.postcode,
    ].where((part) => part.trim().isNotEmpty).join(', ');
  }
}
