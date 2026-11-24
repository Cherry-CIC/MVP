import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/core/models/model.dart';

const dummyProducts = [
  Product(
    userId: "demo-user",
    id: "1",
    name: "Men's Grey Button-up T-Shirt",
    description:
        "Grey short-sleeve button-up shirt in a soft cotton blend. Worn a few times, no marks or fading. True to size.",
    quality: "8/Great",
    size: "M",
    postageSizeId: "AbCdE",
    productImages: [
      AppImages.mensTShirt,
      AppImages.mensTShirt,
    ],
    donation: 6.40,
    price: 7.00,
    securityFee: 7.00,
    likes: 8,
    number: 8,
  ),
  Product(
    userId: "demo-user",
    id: "2",
    name: "Shoes",
    description:
        "Casual trainers with light wear on the soles. Clean inside and out, laces included.",
    quality: "6/Good",
    size: "8",
    postageSizeId: "AbCdEfGhI",
    productImages: [
      AppImages.shoes2,
      AppImages.shoes2,
    ],
    donation: 16.00,
    price: 17.00,
    securityFee: 7.00,
    likes: 33,
    number: 8,
  ),
  Product(
    userId: "demo-user",
    id: "3",
    name: "Shoes",
    description:
        "Everyday trainers with some creasing on the toe box. Plenty of wear left in the soles.",
    quality: "6/Good",
    size: "8",
    postageSizeId: "AbCdEdCfE",
    productImages: [
      AppImages.shoes2,
    ],
    donation: 17.00,
    price: 17.00,
    securityFee: 7.00,
    likes: 33,
    number: 9,
  ),
  Product(
    userId: "demo-user",
    id: "4",
    name: "Shoes",
    description:
        "Comfortable trainers, gently used. Minor scuffs on the sides, otherwise in good shape.",
    quality: "6/Good",
    size: "8",
    postageSizeId: "AbCdEkLoI",
    productImages: [
      AppImages.shoes2,
    ],
    donation: 17.00,
    price: 17.00,
    securityFee: 7.00,
    likes: 33,
    number: 9,
  ),
];
