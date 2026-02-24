class CourierModel {
  final String id;
  final String name;

  CourierModel({
    required this.id,
    required this.name,
  });

  factory CourierModel.fromJson(Map<String, dynamic> json) {
    return CourierModel(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}
