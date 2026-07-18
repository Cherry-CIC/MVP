import 'package:cherry_mvp/core/config/app_images.dart';
import 'package:cherry_mvp/core/config/feature_flags.dart';
import 'package:cherry_mvp/features/search/widgets/search.dart';
import 'package:flutter/material.dart';

/// A reusable navigation bar widget that be use across the app.
class CherryBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final Color? selectedColor;
  final Color? unselectedColor;

  const CherryBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    this.selectedColor,
    this.unselectedColor,
  });

  @override
  Widget build(BuildContext context) {
    const giveIndex = FeatureFlags.showInbox ? 2 : 1;
    const profileIndex = giveIndex + (FeatureFlags.showSearchNavigation ? 2 : 1);
    final selectedColor = this.selectedColor ?? Theme.of(context).colorScheme.primary;
    final unselectedColor = this.unselectedColor ?? Theme.of(context).colorScheme.onSurfaceVariant;
    return DecoratedBox(
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
        items: [
          BottomNavigationBarItem(
            icon: Image.asset(
              AppImages.icHome,
              width: 24,
              height: 24,
              color: selectedIndex == 0 ? selectedColor : unselectedColor,
            ),
            label: 'Home',
          ),
          if (FeatureFlags.showInbox)
            BottomNavigationBarItem(
              icon: Image.asset(
                AppImages.icMessage,
                width: 24,
                height: 24,
                color: selectedIndex == 1 ? selectedColor : unselectedColor,
              ),
              label: 'Inbox',
            ),
          BottomNavigationBarItem(
            icon: Image.asset(
              AppImages.icAdd,
              width: 24,
              height: 24,
              color: selectedIndex == giveIndex ? selectedColor : unselectedColor,
            ),
            label: 'Give',
          ),
          if (FeatureFlags.showSearchNavigation) BottomNavigationBarItem(icon: Search(), label: 'Search'),
          BottomNavigationBarItem(
            icon: Image.asset(
              AppImages.icProfile,
              width: 24,
              height: 24,
              color: selectedIndex == profileIndex ? selectedColor : unselectedColor,
            ),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
