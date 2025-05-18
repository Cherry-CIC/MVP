import 'package:cherry_mvp/core/config/app_colors.dart';
import 'package:cherry_mvp/core/config/app_images.dart';
import 'package:cherry_mvp/core/reusablewidgets/footer_nav.dart';
import 'package:flutter/material.dart';

class SearchScreenPage extends StatefulWidget {
  const SearchScreenPage({super.key});

  @override
  State<SearchScreenPage> createState() => _SearchScreenPageState();
}

class _SearchScreenPageState extends State<SearchScreenPage> {
  int _selectedIndex = 2; // Search is selected by default
  final TextEditingController _searchController = TextEditingController();

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          width: double.infinity,
          // height:649.35,
          decoration:  BoxDecoration(

            gradient: RadialGradient(


            radius: 1,
              center: Alignment.centerRight,
              stops: [
                0.0, // 0%
                1.0, // 100%
              ],
              colors: [Color(0xffFFC0D4), Color(0xFFFFF2F6)],
            ),
          ),
          child: Column(
            children: [


              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 18.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  width: 404,
                  height: 51,
                  decoration: BoxDecoration(
                    color: Color(0XFFDFDFDF),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search Items',
                      hintStyle: TextStyle(color: AppColors.greyTextColor),
                      prefixIcon: Image(
                          width: 13.34,
                          height: 13.34,
                          color: AppColors.greyNavFooter,
                          image: AssetImage(AppImages.icSearch)),
                      suffixIcon:  Image(
                          width: 22.53,
                          height: 16,
                          color: AppColors.greyNavFooter,
                          image: AssetImage(AppImages.icCam)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),



              Padding(
                padding:  EdgeInsets.only(right: 8.0, left: 20.0, top: 8.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(

                    'No products found... 🔎 ',
                    style: TextStyle(
                      color: Color(0Xff707070),
                      fontWeight: FontWeight.w400,
                      fontSize: 20,
                      letterSpacing: 0,
                      height: 1,
                      fontFamily: 'Raleway-Regular',
                    ),
                    textAlign: TextAlign.left,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CherryBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemSelected: _onItemTapped,
        selectedColor: AppColors.primary,
        unselectedColor: AppColors.greyNavFooter,
      ),
    );
  }

}