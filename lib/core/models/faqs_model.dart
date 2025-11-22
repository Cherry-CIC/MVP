class FaqEntry {
  final String question;
  final String answer;

  const FaqEntry({
    required this.question,
    required this.answer,
  });
}

class FaqCategory {
  final String title;
  final List<FaqEntry> entries;

  const FaqCategory({
    required this.title,
    required this.entries,
  });
}