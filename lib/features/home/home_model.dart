import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/core/models/model.dart';

const dummyCategories = [
  Category(
      name: "Clothing",
      images: [
        AppImages.clothing1,
        AppImages.clothing2,
        AppImages.clothing3,
        AppImages.clothing4
      ],
      number: 109),
  Category(
      name: "Shoes",
      images: [
        AppImages.shoes1,
        AppImages.shoes2,
        AppImages.shoes3,
        AppImages.shoes4
      ],
      number: 530),
];

const dummyProducts = [
  Product(name: "Men's Grey Button-up T-Shirt", product_image: AppImages.mensTShirt, price: 7.00, charity_image: AppImages.homeStart, likes: 8, number: 8),
  Product(name: "Men's Grey Button-up T-Shirt", product_image: AppImages.mensTShirt, price: 7.00, charity_image: AppImages.homeStart, likes: 8, number: 8),
  Product(name: "Men's Grey Button-up T-Shirt", product_image: AppImages.mensTShirt, price: 7.00, charity_image: AppImages.homeStart, likes: 8, number: 8),
  Product(name: "Men's Grey Button-up T-Shirt", product_image: AppImages.mensTShirt, price: 7.00, charity_image: AppImages.homeStart, likes: 8, number: 8),
];



const dummyCharityLogos = [
  CharityLogo(charity_image: AppImages.homeStart),
  CharityLogo(charity_image: AppImages.homeStart),
  CharityLogo(charity_image: AppImages.homeStart),
  CharityLogo(charity_image: AppImages.homeStart),
  CharityLogo(charity_image: AppImages.homeStart),
  CharityLogo(charity_image: AppImages.homeStart), 
];