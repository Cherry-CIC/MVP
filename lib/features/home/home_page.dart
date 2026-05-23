import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  static final List<Widget> _pages = <Widget>[HomeScreen(), MessagePage(), ProfilePage()];

  void _onItemTapped(int index) {
    switch (index) {
      case 0:
        _pageController.jumpToPage(0);
        break;
      case 1:
        _pageController.jumpToPage(1);
        break;
      case 2:
        showDialog(
          context: context,
          builder: (context) => Dialog.fullscreen(
            child: DonationPage(),
          ),
        );
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
