class PickupPoint {
  final String id;
  final String name;
  final String addressLine1;
  final String city;
  final String postalCode;
  final String country;
  final String? carrier;
  final double? distanceMeters;
  final String? latitude;
  final String? longitude;
  final bool openTomorrow;
  final bool openUpcomingWeek;

  const PickupPoint({
    required this.id,
    required this.name,
    required this.addressLine1,
    required this.city,
    required this.postalCode,
    required this.country,
    this.carrier,
    this.distanceMeters,
    this.latitude,
    this.longitude,
    this.openTomorrow = false,
    this.openUpcomingWeek = false,
  });

  factory PickupPoint.fromJson(Map<String, dynamic> json) {
    return PickupPoint(
      id: _readString(json, ['id']),
      name: _readString(json, ['name']),
      addressLine1: _readString(json, ['addressLine1', 'address', 'line1', 'street']),
      city: _readString(json, ['city']),
      postalCode: _readString(json, ['postalCode', 'postcode', 'postCode']),
      country: _readString(json, ['country']),
      carrier: _readNullableString(json, ['carrier']),
      distanceMeters: _readDouble(json, ['distanceMeters']),
      latitude: _readNullableString(json, ['latitude', 'lat']),
      longitude: _readNullableString(json, ['longitude', 'long', 'lng']),
      openTomorrow: _readBool(json, ['openTomorrow']),
      openUpcomingWeek: _readBool(json, ['openUpcomingWeek']),
    );
  }

  bool get isValid =>
      id.isNotEmpty &&
      name.isNotEmpty &&
      addressLine1.isNotEmpty &&
      city.isNotEmpty &&
      postalCode.isNotEmpty &&
      country.isNotEmpty;

  String get displayAddress {
    return [addressLine1, city, postalCode].where((part) => part.trim().isNotEmpty).join(', ');
  }

  String get distanceLabel {
    final distance = distanceMeters;
    if (distance == null) return '';
    if (distance < 1000) return '${distance.round()} m away';
    return '${(distance / 1000).toStringAsFixed(1)} km away';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'addressLine1': addressLine1,
      'city': city,
      'postalCode': postalCode,
      'country': country,
      'carrier': carrier == null || carrier!.isEmpty ? 'inpost_gb' : carrier,
      if (distanceMeters != null) 'distanceMeters': distanceMeters,
      if (latitude != null && latitude!.isNotEmpty) 'latitude': latitude,
      if (longitude != null && longitude!.isNotEmpty) 'longitude': longitude,
      'openTomorrow': openTomorrow,
      'openUpcomingWeek': openUpcomingWeek,
    };
  }

  static String _readString(Map<String, dynamic> json, List<String> keys) {
    return _readNullableString(json, keys) ?? '';
  }

  static String? _readNullableString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
    return null;
  }

  static double? _readDouble(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
    }
    return null;
  }

  static bool _readBool(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is bool) return value;
      if (value is String) return value.toLowerCase() == 'true';
    }
    return false;
  }
}
