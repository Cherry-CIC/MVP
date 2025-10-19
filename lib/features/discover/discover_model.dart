import 'package:cherry_mvp/core/config/app_images.dart';
import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/core/models/model.dart';

final List<Charity> dummyCharities = [
  Charity(
    charityName: "WaterAid",
    description:
        "In a small village in Malawi, WaterAid recently completed the construction of a new well, providing clean, safe drinking water to hundreds of residents. No more long treks for water. No more toxic sources!",
    charityImage: AppImages.discoverImage1,
    charityLogo: AppImages.waterAidLogo,
    likes: 3,
  ),
  Charity(
    charityName: "WWF",
    description:
        "After years of conservation efforts, WWF announced a rise in sea turtle hatchlings on a beach in Costa Rica! Thanks to beach patrols and community engagement, baby turtles are making their way to the ocean in record numbers. Help them shell-ebrate!",
    charityImage: AppImages.wwf,
    charityLogo: AppImages.wwfLogo,
    likes: 3,
  ),
  Charity(
    charityName: "Shelter",
    description:
        "Shelter UK helped dozens of families move into secure housing last month. Thanks to their advocacy and support, families now have a place to call home.",
    charityImage: AppImages.shelter,
    charityLogo: AppImages.shelterLogo,
    likes: 3,
  ),
  Charity(
    charityName: "Mind",
    description:
        "The mental health charity Mind has rolled out a series of free community workshops across the UK, reaching over 5,000 people. These sessions equip individuals with tools to manage stress and anxiety.",
    charityImage: AppImages.mind,
    charityLogo: AppImages.mindLogo,
    likes: 3,
  ),
];

const dummyProducts = [
  Product(
    userId: "demo-user",
    id: "1",
    name: "Men's Grey Button-up T-Shirt",
    description:
        "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
    quality: "8/Great",
    size: "M",
    productImages: [
      AppImages.mensTShirt,
      AppImages.mensTShirt,
    ],
    donation: 6.40,
    price: 7.00,
    likes: 8,
    number: 8,
  ),
  Product(
    userId: "demo-user",
    id: "2",
    name: "Shoes",
    description:
        "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
    quality: "6/Good",
    size: "8",
    productImages: [
      AppImages.shoes2,
      AppImages.shoes2,
    ],
    donation: 16.00,
    price: 17.00,
    likes: 33,
    number: 8,
  ),
  Product(
    userId: "demo-user",
    id: "3",
    name: "Shoes",
    description:
        "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
    quality: "6/Good",
    size: "8",
    productImages: [
      AppImages.shoes2,
    ],
    donation: 17.00,
    price: 17.00,
    likes: 33,
    number: 9,
  ),
  Product(
    userId: "demo-user",
    id: "4",
    name: "Shoes",
    description:
        "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
    quality: "6/Good",
    size: "8",
    productImages: [
      AppImages.shoes2,
    ],
    donation: 17.00,
    price: 17.00,
    likes: 33,
    number: 9,
  )
];
