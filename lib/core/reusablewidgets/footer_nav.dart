import 'package:cherry_mvp/core/config/app_colors.dart';
import 'package:cherry_mvp/core/config/app_images.dart';
import 'package:cherry_mvp/features/donate/donate_screen.dart';
import 'package:cherry_mvp/features/home/all_categories.dart';
import 'package:flutter/material.dart';



/// A reusable navigation bar widget that be use across the app.
class CherryBottomNavBar extends StatefulWidget {
  int selectedIndex;
  final Function(int) onItemSelected;
  final Color selectedColor;
  final Color unselectedColor;

  CherryBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    this.selectedColor = AppColors.selectedTab,
    this.unselectedColor = AppColors.grey1,
  });

  @override
  State<CherryBottomNavBar> createState() => _CherryBottomNavBarState();
}

class _CherryBottomNavBarState extends State<CherryBottomNavBar> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 430,
      height: 89,
      //padding: EdgeInsets.symmetric(horizontal: 25.0,vertical: 10),
      decoration: const BoxDecoration(

        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
        bottomRight: Radius.circular(20),
       ),

        gradient: RadialGradient(


          transform: GradientRotation(-12.58),
          colors: [Color(0xFFFFC0D4), Color(0xFFFFF2F6)],
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: widget.selectedIndex,
        onTap: (index) {
          setState(() {
            widget.selectedIndex = index;
          });
          // Handle navigation based on index
          switch (index) {
            case 0:
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(builder: (context) => AllCategoriesPage()), // Replace current page
              // );
              break;
            case 1:
              Navigator.push(context, MaterialPageRoute(builder:(context)=>AllCategoriesPage(),),);
              break;
            case 2:
            // Notification navigation
            Navigator.push(context, MaterialPageRoute(builder:(context)=>DonateScreen(),),);
              break;
            case 3:
            // Profile navigation
              //Navigator.push(context, MaterialPageRoute(builder:(context)=>ProfilePage(),),);
              break;
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: widget.selectedColor,
        unselectedItemColor: widget.unselectedColor,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        elevation: 0,
        items:  [
          BottomNavigationBarItem(
            icon: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image(
                  width: 39.93,
                  height: 30.29,
                  color: widget.selectedIndex == 0 ? widget.selectedColor : widget.unselectedColor,
                  image: AssetImage(AppImages.icHome)),
            ),
            label: 'Home',
          ),

          BottomNavigationBarItem(
            icon: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image(
                  width: 39.93,
                  height: 30.29,
                  image: AssetImage(AppImages.icMessage)),
            ),
            label: 'Inbox',
          ),

          BottomNavigationBarItem(
            icon: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image(
                  width: 39.93,
                  height: 30.29,
                  image: AssetImage(AppImages.icAdd)),
            ),
            label: 'Give',
          ),
          BottomNavigationBarItem(

            icon: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image(
                  width: 39.93,
                  height: 30.29,
                  image: AssetImage(AppImages.icSearch)),
            ),
            label: 'Search',
          ),


          BottomNavigationBarItem(
            icon: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image(
                  width: 39.93,
                  height: 30.29,
                  image: AssetImage(AppImages.icProfile)),
            ),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}