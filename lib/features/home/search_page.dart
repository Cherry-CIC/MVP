import 'package:cherry_mvp/core/config/app_colors.dart';
import 'package:cherry_mvp/core/config/app_images.dart';
import 'package:cherry_mvp/core/reusablewidgets/footer_nav.dart';
import 'package:flutter/material.dart';

class SearchScreenPage extends StatefulWidget {
  const SearchScreenPage({super.key, required initialCategory});

  @override
  State<SearchScreenPage> createState() => _SearchScreenPageState();
}

class _SearchScreenPageState extends State<SearchScreenPage> {
  int _selectedIndex = 2; // Search is selected by default
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _hasSearched = false;
  Color _iconColor = AppColors.selectedTab;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _hasSearched = query.isNotEmpty;
      // Simulate search - replace with actual search logic
      _searchResults = []; // No results for now
    });
  }

  void _onCategoryTapped(String category) {
    // Handle category selection
    print('Selected category: $category');
    // You can navigate to category page or filter results here
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  final List<Map<String, dynamic>> categories = [
    {'icon': Image.asset(AppImages.global_charity, height: 25, width: 25,), 'label': 'Charities','color': AppColors.selectedTab, },
    {'icon': Image.asset(AppImages.women), 'label': 'Women','color': AppColors.selectedTab,  },
    {'icon': Image.asset(AppImages.men), 'label': 'Men','color': AppColors.selectedTab, },
    {'icon': Image.asset(AppImages.children), 'label': 'Children','color': AppColors.selectedTab, },
    {'icon': Image.asset(AppImages.accessories), 'label': 'Accessories','color': AppColors.selectedTab, },
    {'icon': Image.asset(AppImages.unisex), 'label': 'Unisex', 'color': AppColors.selectedTab,},
    {'icon': Image.asset(AppImages.designer), 'label': 'Designer', 'color': AppColors.selectedTab,},
    {'icon': Image.asset(AppImages.book), 'label': 'Books','color': AppColors.selectedTab, },
    {'icon': Image.asset(AppImages.toy), 'label': 'Toys & Board Games','color': AppColors.selectedTab, },
    {'icon': Image.asset(AppImages.cd), 'label': 'CD\'s & Vinyl','color': AppColors.selectedTab, },
    {'icon': Image.asset(AppImages.dvd), 'label': 'DVD\'s & Video Games','color': AppColors.selectedTab, },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      body: SafeArea(
        child: Container(
          width: double.infinity,

          decoration: BoxDecoration(
            color:  AppColors.bgColor,
            // borderRadius: BorderRadius.circular(15),
            // gradient: RadialGradient(
            //   radius: 1,
            //   center: Alignment.centerRight,
            //   stops: [0.0, 1.0],
            //   colors: [Color(0xffFFC0D4), Color(0xFFFFF2F6)],
            // ),
          ),
          child: Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  width: double.infinity,
                  height: 51,
                  decoration: BoxDecoration(
                    color: Color(0XFFDFDFDF),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search items or members',
                      hintStyle: TextStyle(color: AppColors.greyTextColor),
                      prefixIcon:  Image.asset(AppImages.icSearch,height:22.5 ,width: 22.5, color: AppColors.grey1,),
                      suffixIcon: Image.asset(AppImages.icCam,height:22.5 ,width: 22.5,),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),

              // Content area
              Expanded(
                child: _hasSearched && _searchResults.isEmpty
                    ? // Show "No products found" when search is performed but no results
                Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
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
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
                    : // Show categories when no search is performed
                ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return Container(
                      margin: EdgeInsets.only(bottom: 1),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        border: Border(
                          bottom: BorderSide(
                            color:Color(0XffDFDFDF),
                            width: 1,
                          ),
                        ),
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 1,
                        ),
                        leading: category['icon'],
                        title: Text(
                          category['label'],
                          style: TextStyle(
                            color: AppColors.black,
                            fontWeight: FontWeight.w400,
                            fontSize: 16,
                            letterSpacing: 0,
                            height: 31/16,
                            fontFamily: 'Raleway-Light',
                          ),
                        ),
                        // trailing: Image.asset(
                        //   AppImages.Ic_arrow,
                        //   height: 8.1,
                        //   width: 16.71,
                        //   color: Color(0xff707070),
                        // ),
                        trailing: Icon(
                          Icons.chevron_right,
                            size: 18,
                            color: Color(0xff707070),
                        ),
                        onTap: () => _onCategoryTapped(category['label']),
                      ),
                    );
                  },
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
        unselectedColor: AppColors.grey1,
      ),
    );
  }
}