import 'package:cherry_mvp/core/models/model.dart';
import 'package:cherry_mvp/features/home/home_model.dart';

class HomeRepository {

  List<Product> fetchProducts()  {
    return dummyProducts;
  }
 
  List<NewProduct> fetchNewProducts()  {
    return dummyNewProducts;
  } 
  

}