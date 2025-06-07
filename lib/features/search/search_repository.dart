import 'package:cherry_mvp/core/models/model.dart';
import 'package:cherry_mvp/features/search/search_model.dart';

class SearchRepository { 
 
  List<Charity> fetchCharityCategories()  {
    return dummyCharityCategories;
  }
}