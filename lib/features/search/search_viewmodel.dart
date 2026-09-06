import 'package:cherry_mvp/features/search/search_repository.dart';
import 'package:flutter/cupertino.dart';

class SearchViewModel extends ChangeNotifier {
  final SearchRepository searchRepository;

  SearchViewModel({required this.searchRepository});

  // Search-related methods only
}
