import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cherry_mvp/core/config/feature_flags.dart';
import 'package:cherry_mvp/features/donation/donation_page.dart';
import 'package:cherry_mvp/features/home/widgets/bottom_nav_bar.dart';
import 'package:cherry_mvp/features/home/widgets/home_screen.dart';
import 'package:cherry_mvp/features/messages/message_page.dart';
import 'package:cherry_mvp/features/orders/orders_page.dart';
import 'package:cherry_mvp/features/profile/profile_page.dart';
import 'package:cherry_mvp/features/profile/profile_listings_view_model.dart';
import 'package:cherry_mvp/features/charity_page/charity_viewmodel.dart';
import 'package:cherry_mvp/features/categories/category_view_model.dart';

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
  static const int _profileNavIndex = _giveNavIndex + (FeatureFlags.showSearchNavigation ? 2 : 1);

  int _selectedIndex = 0;
  bool _showOrders = false;
  final PageController _pageController = PageController();

  void _openOrders() {
    if (!_showOrders) {
      setState(() => _showOrders = true);
    }
  }

  void _showProfileRoot() {
    if (_showOrders) {
      setState(() => _showOrders = false);
    }
  }

  void _onItemTapped(int index) {
    if (index == _homeNavIndex) {
      _showProfileRoot();
      _pageController.jumpToPage(_homePageIndex);
      return;
    }

    if (FeatureFlags.showInbox && index == _inboxNavIndex) {
      _showProfileRoot();
      _pageController.jumpToPage(_inboxPageIndex);
      return;
    }

    if (index == _giveNavIndex) {
      // Start loading charities and categories before the donation form is
      // built, so the dropdowns are populated without showing loading states.
      context.read<CharityViewModel>().fetchCharities();
      context.read<CategoryViewModel>().fetchCategories();

      showDialog(
        context: context,
        builder: (context) => Dialog.fullscreen(child: DonationPage()),
      );
      return;
    }

    if (FeatureFlags.showSearchNavigation && index == _searchNavIndex) {
      context.read<SearchController>().openView();
      return;
    }

    if (index == _profileNavIndex) {
      if (_showOrders) {
        _showProfileRoot();
      }
      if (_selectedIndex == _profileNavIndex) {
        context.read<ProfileListingsViewModel>().refreshListings();
      }
      _pageController.jumpToPage(_profilePageIndex);
    }
  }

  void _onPageChanged(int index) {
    var nextSelectedIndex = _homeNavIndex;
    if (index == _profilePageIndex) {
      nextSelectedIndex = _profileNavIndex;
      context.read<ProfileListingsViewModel>().refreshListings();
    } else if (FeatureFlags.showInbox && index == _inboxPageIndex) {
      nextSelectedIndex = _inboxNavIndex;
    }

    setState(() {
      _selectedIndex = nextSelectedIndex;
      if (index != _profilePageIndex) {
        _showOrders = false;
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_showOrders,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _showOrders) {
          _showProfileRoot();
        }
      },
      child: Scaffold(
        body: PageView(
          controller: _pageController,
          onPageChanged: _onPageChanged,
          children: [
            const HomeScreen(),
            if (FeatureFlags.showInbox) const MessagePage(),
            Stack(
              fit: StackFit.expand,
              children: [
                Offstage(
                  offstage: _showOrders,
                  child: TickerMode(
                    enabled: !_showOrders,
                    child: ProfilePage(onOrdersPressed: _openOrders),
                  ),
                ),
                if (_showOrders) MyOrdersPage(onBack: _showProfileRoot),
              ],
            ),
          ],
        ),
        bottomNavigationBar: CherryBottomNavBar(
          selectedIndex: _selectedIndex,
          onItemSelected: _onItemTapped,
          selectedColor: Theme.of(context).colorScheme.primary,
          unselectedColor: Theme.of(context).colorScheme.secondary,
        ),
      ),
    );
  }
}
