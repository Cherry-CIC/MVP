import 'package:flutter/material.dart';

import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/core/models/product_carousel.dart';

const dummyProductCarousel = [
  ProductCarousel(
    image: AppImages.charityProduct1,
    charityLogo: AppImages.logoSaveChildren,
    numberLikes: 25
  ),

  ProductCarousel(
    image: AppImages.charityProduct2,
    charityLogo: AppImages.logoAgeUk,
    numberLikes: 40
  ), 

  ProductCarousel(
    image: AppImages.charityProduct3,
    charityLogo: AppImages.logoBritishHeartFoundation,
    numberLikes: 46
  ), 

  ProductCarousel(
    image: AppImages.charityProduct4,
    charityLogo: AppImages.logoOneNation,
    numberLikes: 56
  ), 

  ProductCarousel(
    image: AppImages.charityProduct5,
    charityLogo: AppImages.logoRedCross,
    numberLikes: 84
  ), 
];
