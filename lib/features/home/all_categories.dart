import 'package:cherry_mvp/core/config/app_colors.dart';
import 'package:cherry_mvp/core/config/app_images.dart';
import 'package:cherry_mvp/core/models/all_categories_model.dart';
import 'package:flutter/material.dart';



/// for all categories of products
final List<ProductCategories >womenCategories = [
  /// for all categories of products
  ProductCategories(
    title: "Charities",
    iconPath: AppImages.Ic_charityCategory,
    hasActionArrow: true,
    /// listing subcategories
    subcategories: [
      "Dresses",
      "Thermals",
      "Shapewear",
      "Seasonal",
      "Sportswear (inner)",
      "T-Shirts",
      "Shirts",
      "Tracksuits",
      "Lounge Wear",
      "Costumes",
    ],
  ),
  ProductCategories(
    title: "Innerwear",
    /// listing subcategories
    subcategories: [
      "Dresses",
      "Thermals",
      "Shapewear",
      "Seasonal",
      "Sportswear (inner)",
      "T-Shirts",
      "Shirts",
      "Tracksuits",
      "Lounge Wear",
      "Costumes",
    ],
    isExpanded: true,
  ),
  ProductCategories(
    title: "Outerwear",
    /// listing subcategories
    subcategories: [
      "Dresses",
      "Thermals",
      "Shapewear",
      "Seasonal",
      "Sportswear (inner)",
      "T-Shirts",
      "Shirts",
      "Tracksuits",
      "Lounge Wear",
      "Costumes",
    ],
    isExpanded: false,
  ),
  ProductCategories(
    title: "Bags",
    /// listing subcategories
    subcategories: [
      "Dresses",
      "Thermals",
      "Shapewear",
      "Seasonal",
      "Sportswear (inner)",
      "T-Shirts",
      "Shirts",
      "Tracksuits",
      "Lounge Wear",
      "Costumes",
    ],
    isExpanded: false,
  ),
  ProductCategories(
    title: "Bottoms",
    /// listing subcategories
    subcategories: [
      "Dresses",
      "Thermals",
      "Shapewear",
      "Seasonal",
      "Sportswear (inner)",
      "T-Shirts",
      "Shirts",
      "Tracksuits",
      "Lounge Wear",
      "Costumes",
    ],
    isExpanded: false,
  ),
  ProductCategories(
    title: "Accessories",
    /// listing subcategories
    subcategories: [],
    isExpanded: false,
  ),
  ProductCategories(
    title: "Shoes",
    /// listing subcategories
    subcategories: [],
    isExpanded: false,
  ),
  ProductCategories(
    title: "Outfits",
    subcategories: [],
    isExpanded: false,
  ),
  ProductCategories(
    title: "Search by Brand",
    hasActionArrow: true,
    subcategories: [],
  ),
  ProductCategories(
    title: "Other",
    hasActionArrow: true,
    subcategories: [],
  ),
];
///other categories needs to be created as well


class AllCategoriesPage extends StatefulWidget {
  const AllCategoriesPage({super.key});

  @override
  State<AllCategoriesPage> createState() => _AllCategoriesPageState();
}

class _AllCategoriesPageState extends State<AllCategoriesPage> {
  String initialSelectedTab = "Women";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      appBar: AppBar(
        title:  SizedBox(
          width: 185,
          height: 36,
          child: Text(
            'All Categories',
            style: TextStyle(
              color: AppColors.secondary,
              fontWeight: FontWeight.w700,
              fontSize: 28,
              letterSpacing: -0.28,
              height: 36 / 28,
              fontFamily: 'Raleway-Bold',
            ),
          ),
        ),
        leading: Center(child: Image.asset(AppImages.Ic_back,height: 16,width: 19,    color:  AppColors.black,),),
        centerTitle: true,
        backgroundColor: AppColors.white,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Image.asset(
              AppImages.Ic_filter,
              width: 24,
              height: 24,

            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  categoryTab("All", false),
                  categoryTab("Women", true),
                  categoryTab("Men", false),
                  categoryTab("Kids", false),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: womenCategories.length,
              itemBuilder: (context, index) {
                return categoryItem(womenCategories[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget categoryTab(String title, bool isSelected) {
    return Container(
      width: isSelected?107:70,
      height: 40,
      decoration: BoxDecoration(
        color:   const Color(0xFFE5EBFC),
        borderRadius: BorderRadius.circular(9.0),
        border: Border.all(
          color: isSelected ? Color(0xFFF90653): Color(0xffF9F9F9), // Border color
          width: 1, // Border width
        ),

      ),
      alignment: Alignment.center,


      margin: const EdgeInsets.only(right: 8.0),
      child: Text(title,
        style: TextStyle(

        fontWeight: FontWeight.w500,
        fontSize: isSelected?18:17,
        letterSpacing: 0,
        height: 23 / 18,
        fontFamily: 'Raleway-Medium',
        color: isSelected ? AppColors.primary : AppColors.black,
      ),
    textAlign: TextAlign.center,),
    );
  }

  Widget categoryItem(ProductCategories product) {
    if (product.title == "Charities" || product.title == "Search by Brand" || product.title == "Other") {
      return Container(
        width: 335,
        height: 50,
        margin: const EdgeInsets.only(bottom: 12.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black..withAlpha(100),
              offset: const Offset(0, 5),
              blurRadius: 10,
              spreadRadius: 0,
            ),
          ],
        ),
        child: ListTile(
         contentPadding: const EdgeInsets.symmetric(horizontal: 20.0, ),
          title: Text(
            product.title,
            style: TextStyle(

              fontWeight: FontWeight.w700,
              fontSize: 17,
              letterSpacing: -0.17,
              height: 21 / 17,
              fontFamily: 'Raleway-Bold',
              color:  AppColors.secondary ,
            ),
          ),
          trailing: GestureDetector(
            onTap: () {
             //Navigate to the next screen or perform any other action.
            },
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Image.asset(AppImages.Ic_arrow,width: 16,height: 16,),
            ),
          ),
          leading: product.title == "Charities"
              ? Positioned(
              top: 125,
              left: 22,
              child: Image.asset(product.iconPath ?? "", width: 46, height: 60))
              : null,
        ),
      );
    } else {
      return Container(
        margin: const EdgeInsets.only(bottom: 12.0),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(100),
              offset: const Offset(0, 5),
              blurRadius: 10,
              spreadRadius: 0,
            ),
          ],
        ),
        /// container for categories without arrow
        child: ExpansionTile(
          iconColor: AppColors.primary,
          initiallyExpanded: product.isExpanded ?? false,
          title: Text(
            product.title,
            style: TextStyle(

              fontWeight: FontWeight.w700,
              fontSize: 17,
              letterSpacing: -0.17,
              height: 21 / 17,
              fontFamily: 'Raleway-Bold',
              color:  AppColors.secondary ,
            ),
          ),
          /// for subcategories if
          children: product.subcategories?.isNotEmpty == true
              ? [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 3.0,
                crossAxisSpacing: 12.0,
                mainAxisSpacing: 12.0,
                children: product.subcategories!.map((sub) {
                  return Container(
                    width: 163,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(
                        color: const Color(0xFFFFEBEB),
                        width: 2, // Border width
                      ),
                    ),
                    child: Center(
                      child: Text(
                        sub,
                        style: TextStyle(

                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          letterSpacing: 0,
                          height:1,
                          fontFamily: 'Raleway-Bold',
                          color:  AppColors.secondary ,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }).toList(),
              ),
            )
          ]
              : [],
        ),
      );
    }
  }
}