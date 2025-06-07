import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/features/addproduct/addproductpage.dart';
import 'package:cherry_mvp/features/home/home_viewmodel.dart';
import 'package:cherry_mvp/features/home/widgets/bottom_nav_bar.dart';
import 'package:cherry_mvp/features/home/widgets/home_screen.dart';
import 'package:cherry_mvp/features/messages/messagepage.dart';
import 'package:cherry_mvp/features/profile/profilepage.dart';
import 'package:cherry_mvp/features/search/searchpage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() {
    return HomePageState();
  }
}

class HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  static final List<Widget> _pages = <Widget>[
    HomeScreen(),
    MessagePage(),
    SearchPage(),
    AddProductPage(),
    ProfilePage()
    //add other pages for the bottom sheet here
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.jumpToPage(index);
  }

  void _onPageChanged(int index) {
    setState(() {
      _selectedIndex = index;
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
      backgroundColor: AppColors.bgColor,
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: _pages,
      ),
      bottomNavigationBar: CherryBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemSelected: _onItemTapped,
        selectedColor: AppColors.primary,
        unselectedColor: AppColors.greyNavFooter,
      ),
    );
  }
}

