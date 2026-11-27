import 'package:cherry_mvp/features/discover/discover_page.dart';
import 'package:cherry_mvp/features/search/widgets/search.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cherry_mvp/core/config/feature_flags.dart';
import 'package:cherry_mvp/core/router/nav_provider.dart';
import 'package:cherry_mvp/features/donation/donation_page.dart';
import 'package:cherry_mvp/features/home/widgets/bottom_nav_bar.dart';
import 'package:cherry_mvp/features/home/widgets/home_screen.dart';
import 'package:cherry_mvp/features/messages/message_page.dart';
import 'package:cherry_mvp/features/orders/orders_page.dart';
import 'package:cherry_mvp/features/orders/widgets/delivery_reminder_host.dart';
import 'package:cherry_mvp/features/profile/profile_page.dart';
import 'package:cherry_mvp/features/profile/profile_listings_view_model.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.deliveryTimer});

  final Widget? deliveryTimer;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const int _homePageIndex = 0;
  static const int _discoverPageIndex = 1;
  static const int _inboxPageIndex = 2;
  static const int _profilePageIndex = FeatureFlags.showInbox ? 3 : 2;

  int _selectedIndex = CherryNavIndices.home;
  bool _showOrders = false;
  final PageController _pageController = PageController();
  NavigationProvider? _navigationProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nextNavigator = context.read<NavigationProvider?>();
    if (_navigationProvider != nextNavigator) {
      _navigationProvider?.unregisterMainTabSelector(_onItemTapped);
      _navigationProvider = nextNavigator;
      _navigationProvider?.registerMainTabSelector(_onItemTapped);
    }
  }

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

  void _onItemTapped(int index) async {
    if (index == CherryNavIndices.home) {
      _showProfileRoot();
      _pageController.jumpToPage(_homePageIndex);
      DeliveryReminderHost.setHomeSelected(context, true);
      return;
    }

    if (index == CherryNavIndices.discover) {
      _showProfileRoot();
      DeliveryReminderHost.setHomeSelected(context, false);
      _pageController.jumpToPage(_discoverPageIndex);
      return;
    }

    if (FeatureFlags.showInbox && index == CherryNavIndices.inbox) {
      _showProfileRoot();
      DeliveryReminderHost.setHomeSelected(context, false);
      _pageController.jumpToPage(_inboxPageIndex);
      return;
    }

    if (index == CherryNavIndices.give) {
      final posted = await showDialog<bool>(
        context: context,
        builder: (context) => Dialog.fullscreen(child: DonationPage()),
      );
      if (posted == true && mounted) {
        _onItemTapped(CherryNavIndices.profile);
      }
      return;
    }

    if (FeatureFlags.showSearchNavigation && index == CherryNavIndices.search) {
      openSearch(context);
      return;
    }

    if (index == CherryNavIndices.profile) {
      if (_showOrders) {
        _showProfileRoot();
      }
      if (_selectedIndex == CherryNavIndices.profile) {
        context.read<ProfileListingsViewModel>().refreshListings();
      }
      DeliveryReminderHost.setHomeSelected(context, false);
      _pageController.jumpToPage(_profilePageIndex);
    }
  }

  void _onPageChanged(int index) {
    var nextSelectedIndex = CherryNavIndices.home;
    if (index == _discoverPageIndex) {
      nextSelectedIndex = CherryNavIndices.discover;
    } else if (index == _profilePageIndex) {
      nextSelectedIndex = CherryNavIndices.profile;
      context.read<ProfileListingsViewModel>().refreshListings();
    } else if (FeatureFlags.showInbox && index == _inboxPageIndex) {
      nextSelectedIndex = CherryNavIndices.inbox;
    }

    setState(() {
      _selectedIndex = nextSelectedIndex;
      if (index != _profilePageIndex) {
        _showOrders = false;
      }
    });
    DeliveryReminderHost.setHomeSelected(context, index == _homePageIndex);
  }

  @override
  void dispose() {
    _navigationProvider?.unregisterMainTabSelector(_onItemTapped);
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
            HomeScreen(onOpenDiscover: () => _onItemTapped(CherryNavIndices.discover)),
            const DiscoverPage(showBackButton: false),
            if (FeatureFlags.showInbox) const MessagePage(),
            Stack(
              fit: StackFit.expand,
              children: [
                Offstage(
                  offstage: _showOrders,
                  child: TickerMode(
                    enabled: !_showOrders,
                    child: ProfilePage(
                      onOrdersPressed: _openOrders,
                      onTabSelected: _onItemTapped,
                    ),
                  ),
                ),
                if (_showOrders) MyOrdersPage(onBack: _showProfileRoot),
              ],
            ),
          ],
        ),
        floatingActionButton: _selectedIndex == CherryNavIndices.home ? widget.deliveryTimer : null,
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
