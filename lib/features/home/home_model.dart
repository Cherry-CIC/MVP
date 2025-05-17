import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/core/models/model.dart';


const dummyProducts = [
  Product(name: "Men's Grey Button-up T-Shirt", quality: "8/Great", product_image: AppImages.mensTShirt, price: 7.00, charity_image: AppImages.homeStart, likes: 8, number: 8),
  Product(name: "Shoes", quality: "6/Good", product_image: AppImages.shoes2, price: 17.00, charity_image: AppImages.homeStart, likes: 33, number: 8)
];



var dummyNewProducts = [
  const NewProduct(product_name: "Example product 1", product_image: AppImages.product1, description: "6/Very Good", likes: 3, price: 3.00, included_price: 3.30, charity_image: AppImages.product1),

  const NewProduct(product_name: "Example product 2", product_image: AppImages.product2, description: "6/Very Good", likes: 4, price: 4.00, included_price: 4.30, charity_image: AppImages.product1),
  
  const NewProduct(product_name: "Example product 3", product_image: AppImages.product3, description: "6/Very Good", likes: 5, price: 5.00, included_price: 5.30, charity_image: AppImages.product1),
  
  NewProduct(product_name: "Example product 4", product_image: AppImages.product4, description: "6/Very Good", likes: 6, price: 6.00, included_price: 6.30, charity_image: AppImages.product1),
  
  const NewProduct(product_name: "Example product 5", product_image: AppImages.product5, description: "6/Very Good", likes: 7, price: 7.00, included_price: 7.30, charity_image: AppImages.product1),
  
  const NewProduct(product_name: "Example product 6", product_image: AppImages.product6, description: "6/Very Good", likes: 8, price: 8.00, included_price: 8.30, charity_image: AppImages.product1),
]; 
 
