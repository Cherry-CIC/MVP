import 'package:cherry_mvp/core/router/nav_routes.dart';
import 'package:cherry_mvp/features/home/home_viewmodel.dart';
import 'package:cherry_mvp/features/home/widgets/bottom_nav_bar.dart';
import 'package:cherry_mvp/features/home/widgets/home_screen.dart';
import 'package:cherry_mvp/features/messages/message_page.dart';
import 'package:cherry_mvp/features/profile/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  static final List<Widget> _pages = <Widget>[
    HomeScreen(),
    MessagePage(),
    ProfilePage()
    //add other pages for the bottom sheet here
  ];

  void _onItemTapped(int index) {
    switch (index) {
      case 0:
        _pageController.jumpToPage(0);
        break;
      case 1:
        _pageController.jumpToPage(1);
        break;
      case 2:
        Navigator.of(context).pushNamed(AppRoutes.donations);
        break;
      case 3:
        context.read<SearchController>().openView();
        break;
      case 4:
        _pageController.jumpToPage(2);
        break;
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      switch (index) {
        case 0:
          _selectedIndex = 0;
          break;
        case 1:
          _selectedIndex = 1;
          break;
        case 2:
          _selectedIndex = 4;
          break;
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
    // ignore: unused_local_variable
    final navigator = Provider.of<HomeViewModel>(context, listen: false);

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
