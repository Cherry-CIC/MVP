class CustomSearchDelegate extends SearchDelegate<String> {
  // Dummy list
  final List<String> searchList = [
    "Shoes",
    "Handbags",
    "Shirts",
    "Watches",
    "Socks",
    "Tops",
    "Sunglasees",
    "Trainers,
    "Shorts",
    "Mens",
    "Ladies",
    "Sale",
  ];

  // These methods are mandatory you cannot skip them.

  @override
  List<Widget> buildActions(BuildContext context) {
    // Build the clear button.
  }

  @override
  Widget buildLeading(BuildContext context) {
    // Build the leading icon.
  }

  @override
  Widget buildResults(BuildContext context) {
    // Build the search results.
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    // Build the search suggestions.
  }
}
