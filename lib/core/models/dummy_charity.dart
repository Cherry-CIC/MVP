class DummyCharity {
  final String? id;
  final String charityName;
  final String charityImage;
  final String description;
  final String? charityLogo;
  final bool logoUsesDarkBackground;
  final int likes;
  final Set<String> tags;

  const DummyCharity({
    this.id,
    required this.charityName,
    required this.charityImage,
    required this.description,
    this.charityLogo,
    this.logoUsesDarkBackground = false,
    required this.likes,
    this.tags = const {},
  });
}
