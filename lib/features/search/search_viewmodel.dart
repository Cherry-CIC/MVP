
import 'package:cherry_mvp/features/search/search_repository.dart';
import 'package:flutter/cupertino.dart';
import 'package:logging/logging.dart';

class SearchViewModel extends ChangeNotifier {

  // ignore: unused_field
  final _log = Logger('SearchViewModel');
  final SearchRepository searchRepository;

  SearchViewModel({required this.searchRepository});
 
  // Search-related methods only
}