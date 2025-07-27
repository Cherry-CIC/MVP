class Category {
  final String name;
  final String image;

  const Category({
    required this.name,
    required this.image,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Category && other.name == name;
  }

  @override
  int get hashCode => name.hashCode;
}
