import 'package:cherry_mvp/core/config/app_images.dart';
import 'package:cherry_mvp/core/config/feature_flags.dart';
import 'package:cherry_mvp/features/search/widgets/search.dart';
import 'package:flutter/material.dart';

/// Footer item positions, shared by every screen that shows [CherryBottomNavBar].
class CherryNavIndices {
  const CherryNavIndices._();

  static const int home = 0;
  static const int discover = 1;
  static const int inbox = 2;
  static const int give = FeatureFlags.showInbox ? 3 : 2;
  static const int search = give + 1;
  static const int profile = give + (FeatureFlags.showSearchNavigation ? 2 : 1);
}

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedColor = this.selectedColor ?? Theme.of(context).colorScheme.primary;
    final unselectedColor = this.unselectedColor ?? Theme.of(context).colorScheme.onSurfaceVariant;
    final gradientColors = isDark
        ? const [Color(0xFF2E1A22), Color(0xFF18181B)]
        : const [Color(0xFFFFC0D4), Color(0xFFFFF2F6)];

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(20),
        ),
        gradient: RadialGradient(
          transform: const GradientRotation(-12.58),
          colors: gradientColors,
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: onItemSelected,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
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
              color: selectedIndex == CherryNavIndices.home ? selectedColor : unselectedColor,
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              selectedIndex == CherryNavIndices.discover ? Icons.grid_view_rounded : Icons.grid_view_outlined,
              size: 24,
              color: selectedIndex == CherryNavIndices.discover ? selectedColor : unselectedColor,
            ),
            label: 'Discover',
          ),
          if (FeatureFlags.showInbox)
            BottomNavigationBarItem(
              icon: Image.asset(
                AppImages.icMessage,
                width: 24,
                height: 24,
                color: selectedIndex == CherryNavIndices.inbox ? selectedColor : unselectedColor,
              ),
              label: 'Inbox',
            ),
          BottomNavigationBarItem(
            icon: Image.asset(
              AppImages.icAdd,
              width: 24,
              height: 24,
              color: selectedIndex == CherryNavIndices.give ? selectedColor : unselectedColor,
            ),
            label: 'Give',
          ),
          if (FeatureFlags.showSearchNavigation) BottomNavigationBarItem(icon: Search(), label: 'Search'),
          BottomNavigationBarItem(
            icon: Image.asset(
              AppImages.icProfile,
              width: 24,
              height: 24,
              color: selectedIndex == CherryNavIndices.profile ? selectedColor : unselectedColor,
            ),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
