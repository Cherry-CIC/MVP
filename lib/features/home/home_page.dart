import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cherry_mvp/core/config/feature_flags.dart';
import 'package:cherry_mvp/features/donation/donation_page.dart';
import 'package:cherry_mvp/features/home/widgets/bottom_nav_bar.dart';
import 'package:cherry_mvp/features/home/widgets/home_screen.dart';
import 'package:cherry_mvp/features/messages/message_page.dart';
import 'package:cherry_mvp/features/profile/profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const int _homePageIndex = 0;
  static const int _inboxPageIndex = 1;
  static const int _profilePageIndex = FeatureFlags.showInbox ? 2 : 1;

  static const int _homeNavIndex = 0;
  static const int _inboxNavIndex = 1;
  static const int _giveNavIndex = FeatureFlags.showInbox ? 2 : 1;
  static const int _searchNavIndex = _giveNavIndex + 1;
  static const int _profileNavIndex =
      _giveNavIndex + (FeatureFlags.showSearch ? 2 : 1);

  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  static final List<Widget> _pages = <Widget>[
    HomeScreen(),
    if (FeatureFlags.showInbox) MessagePage(),
    ProfilePage(),
  ];

  void _onItemTapped(int index) {
    if (index == _homeNavIndex) {
      _pageController.jumpToPage(_homePageIndex);
      return;
    }

    if (FeatureFlags.showInbox && index == _inboxNavIndex) {
      _pageController.jumpToPage(_inboxPageIndex);
      return;
    }

    if (index == _giveNavIndex) {
      showDialog(
        context: context,
        builder: (context) => Dialog.fullscreen(child: DonationPage()),
      );
      return;
    }

    if (FeatureFlags.showSearch && index == _searchNavIndex) {
      context.read<SearchController>().openView();
      return;
    }

    if (index == _profileNavIndex) {
      _pageController.jumpToPage(_profilePageIndex);
    }
  }

  void _onPageChanged(int index) {
    var nextSelectedIndex = _homeNavIndex;
    if (index == _profilePageIndex) {
      nextSelectedIndex = _profileNavIndex;
    } else if (FeatureFlags.showInbox && index == _inboxPageIndex) {
      nextSelectedIndex = _inboxNavIndex;
    }

    setState(() {
      _selectedIndex = nextSelectedIndex;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: _pages,
      ),
      bottomNavigationBar: CherryBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemSelected: _onItemTapped,
        selectedColor: Theme.of(context).colorScheme.primary,
        unselectedColor: Theme.of(context).colorScheme.secondary,
      ),
    );
  }
}
