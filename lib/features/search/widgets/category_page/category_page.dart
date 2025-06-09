import 'package:flutter/material.dart';
import 'package:cherry_mvp/core/config/config.dart';

class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key});

  @override
  CategoryPageState createState() => CategoryPageState();
}

class CategoryPageState extends State<CategoryPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 35,
        backgroundColor: AppColors.white,
        leading: IconButton(
          icon: Icon(
            Icons.reply,
            color: AppColors.primary,
          ),
          onPressed: () {},
        ),
        title: Text(
          AppStrings.categoriesText ?? '',
          style: TextStyle(
            fontSize: 15,
            color: AppColors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
            //
            ),
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              Padding(
                padding:
                    const EdgeInsets.only(top: 0.0, right: 15.0, left: 15.0),
                child: Column(children: [
                  SizedBox(
                    height: 10,
                  ),

                  // women categories
                  InkWell(
                    onTap: () {},
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(children: [
                            Row(children: [
                              Image.asset(
                                AppImages.womanIcon,
                                height: 30,
                                width: 30,
                                fit: BoxFit.cover,
                              ),
                              Padding(
                                padding: EdgeInsets.only(left: 20),
                                child: Text(
                                  AppStrings.womenText ?? '',
                                  style: TextStyle(
                                    color: AppColors.black,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ]),
                          ]),
                          Column(children: [
                            Icon(
                              Icons.chevron_right,
                              color: AppColors.black,
                              size: 26,
                            ),
                          ]),
                        ]),
                  ),

                  Divider(),

                  SizedBox(
                    height: 10,
                  ),

                  // men categories
                  InkWell(
                    onTap: () {},
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(children: [
                            Row(children: [
                              Image.asset(
                                AppImages.menIcon,
                                height: 30,
                                width: 30,
                                fit: BoxFit.cover,
                              ),
                              Padding(
                                padding: EdgeInsets.only(left: 20),
                                child: Text(
                                  AppStrings.womenText ?? '',
                                  style: TextStyle(
                                    color: AppColors.black,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ]),
                          ]),
                          Column(children: [
                            Icon(
                              Icons.chevron_right,
                              color: AppColors.black,
                              size: 26,
                            ),
                          ]),
                        ]),
                  ),

                  Divider(),

                  SizedBox(
                    height: 10,
                  ),

                  // children categories
                  InkWell(
                    onTap: () {},
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(children: [
                            Row(children: [
                              Image.asset(
                                AppImages.childrenIcon,
                                height: 30,
                                width: 30,
                                fit: BoxFit.cover,
                              ),
                              Padding(
                                padding: EdgeInsets.only(left: 20),
                                child: Text(
                                  AppStrings.childrenText ?? '',
                                  style: TextStyle(
                                    color: AppColors.black,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ]),
                          ]),
                          Column(children: [
                            Icon(
                              Icons.chevron_right,
                              color: AppColors.black,
                              size: 26,
                            ),
                          ]),
                        ]),
                  ),

                  Divider(),

                  SizedBox(
                    height: 10,
                  ),

                  // unisex categories
                  InkWell(
                    onTap: () {},
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(children: [
                            Row(children: [
                              Image.asset(
                                AppImages.unisexIcon,
                                height: 30,
                                width: 30,
                                fit: BoxFit.cover,
                              ),
                              Padding(
                                padding: EdgeInsets.only(left: 20),
                                child: Text(
                                  AppStrings.unisexText ?? '',
                                  style: TextStyle(
                                    color: AppColors.black,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ]),
                          ]),
                          Column(children: [
                            Icon(
                              Icons.chevron_right,
                              color: AppColors.black,
                              size: 26,
                            ),
                          ]),
                        ]),
                  ),

                  Divider(),

                  SizedBox(
                    height: 10,
                  ),

                  // designer categories
                  InkWell(
                    onTap: () {},
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(children: [
                            Row(children: [
                              Image.asset(
                                AppImages.designIcon,
                                height: 30,
                                width: 30,
                                fit: BoxFit.cover,
                              ),
                              Padding(
                                padding: EdgeInsets.only(left: 20),
                                child: Text(
                                  AppStrings.designerText ?? '',
                                  style: TextStyle(
                                    color: AppColors.black,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ]),
                          ]),
                          Column(children: [
                            Icon(
                              Icons.chevron_right,
                              color: AppColors.black,
                              size: 26,
                            ),
                          ]),
                        ]),
                  ),

                  Divider(),

                  SizedBox(
                    height: 10,
                  ),

                  // profiles categories
                  InkWell(
                    onTap: () {},
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(children: [
                            Row(children: [
                              Image.asset(
                                AppImages.profileIcon,
                                height: 30,
                                width: 30,
                                fit: BoxFit.cover,
                              ),
                              Padding(
                                padding: EdgeInsets.only(left: 20),
                                child: Text(
                                  AppStrings.profilesText ?? '',
                                  style: TextStyle(
                                    color: AppColors.black,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ]),
                          ]),
                          Column(children: [
                            Icon(
                              Icons.chevron_right,
                              color: AppColors.black,
                              size: 26,
                            ),
                          ]),
                        ]),
                  ),

                  Divider(),

                  SizedBox(
                    height: 10,
                  ),

                  // accessories categories
                  InkWell(
                    onTap: () {},
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(children: [
                            Row(children: [
                              Image.asset(
                                AppImages.accessoriesIcon,
                                height: 30,
                                width: 30,
                                fit: BoxFit.cover,
                              ),
                              Padding(
                                padding: EdgeInsets.only(left: 20),
                                child: Text(
                                  AppStrings.accessoriesText ?? '',
                                  style: TextStyle(
                                    color: AppColors.black,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ]),
                          ]),
                          Column(children: [
                            Icon(
                              Icons.chevron_right,
                              color: AppColors.black,
                              size: 26,
                            ),
                          ]),
                        ]),
                  ),

                  Divider(),

                  SizedBox(
                    height: 10,
                  ),

                  // books
                  InkWell(
                    onTap: () {},
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(children: [
                            Row(children: [
                              Image.asset(
                                AppImages.booksIcon,
                                height: 30,
                                width: 30,
                                fit: BoxFit.cover,
                              ),
                              Padding(
                                padding: EdgeInsets.only(left: 20),
                                child: Text(
                                  AppStrings.booksText ?? '',
                                  style: TextStyle(
                                    color: AppColors.black,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ]),
                          ]),
                          Column(children: [
                            Icon(
                              Icons.chevron_right,
                              color: AppColors.black,
                              size: 26,
                            ),
                          ]),
                        ]),
                  ),

                  Divider(),

                  SizedBox(
                    height: 10,
                  ),

                  // toys & board games
                  InkWell(
                    onTap: () {},
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(children: [
                            Row(children: [
                              Image.asset(
                                AppImages.toysIcon,
                                height: 30,
                                width: 30,
                                fit: BoxFit.cover,
                              ),
                              Padding(
                                padding: EdgeInsets.only(left: 20),
                                child: Text(
                                  AppStrings.toysText ?? '',
                                  style: TextStyle(
                                    color: AppColors.black,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ]),
                          ]),
                          Column(children: [
                            Icon(
                              Icons.chevron_right,
                              color: AppColors.black,
                              size: 26,
                            ),
                          ]),
                        ]),
                  ),

                  Divider(),

                  SizedBox(
                    height: 10,
                  ),

                  // dvd & video games
                  InkWell(
                    onTap: () {},
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(children: [
                            Row(children: [
                              Image.asset(
                                AppImages.dvdIcon,
                                height: 30,
                                width: 30,
                                fit: BoxFit.cover,
                              ),
                              Padding(
                                padding: EdgeInsets.only(left: 20),
                                child: Text(
                                  AppStrings.dvdText ?? '',
                                  style: TextStyle(
                                    color: AppColors.black,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ]),
                          ]),
                          Column(children: [
                            Icon(
                              Icons.chevron_right,
                              color: AppColors.black,
                              size: 26,
                            ),
                          ]),
                        ]),
                  ),

                  Divider(),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
