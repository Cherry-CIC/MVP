class PickupPointModel {
  final String id;
  final String name;
  final String address;
  final String postcode;
  final String lat;
  final String long;
  final String courierId;

  PickupPointModel({
    required this.id,
    required this.name,
    required this.address,
    required this.postcode,
    required this.lat,
    required this.long,
    required this.courierId,
  });

  factory PickupPointModel.fromJson(Map<String, dynamic> json) {
    return PickupPointModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      postcode: json['postcode']?.toString() ?? '',
      lat: json['lat']?.toString() ?? '',
      long: json['long']?.toString() ?? '',
      courierId: json['courierId']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'postcode': postcode,
      'lat': lat,
      'long': long,
      'courierId': courierId,
    };
  }
}
