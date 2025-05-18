import 'package:cherry_mvp/core/config/app_colors.dart';
import 'package:cherry_mvp/core/config/app_images.dart';
import 'package:flutter/material.dart';



/// A reusable navigation bar widget that be use across the app.
class CherryBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final Color selectedColor;
  final Color unselectedColor;

  const CherryBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    this.selectedColor = AppColors.selectedTab,
    this.unselectedColor = AppColors.greyNavFooter,
  });

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
        currentIndex: selectedIndex,
        onTap: onItemSelected,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: selectedColor,
        unselectedItemColor: unselectedColor,
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
                  color: selectedIndex == 0 ? selectedColor : unselectedColor,
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