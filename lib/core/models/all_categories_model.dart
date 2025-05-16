class ProductCategories {
  final String title;
  final String? iconPath;
  final List<String>? subcategories;
  final bool? hasActionArrow;
  final bool? isExpanded;

  ProductCategories({
    required this.title,
    this.iconPath,
    this.subcategories = const [],
    this.hasActionArrow = false,
    this.isExpanded = false,
  });
}