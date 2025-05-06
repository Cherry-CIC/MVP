import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/features/addproduct/addproductpage.dart';
import 'package:cherry_mvp/features/home/home_viewmodel.dart';
import 'package:cherry_mvp/features/messages/messagepage.dart';
import 'package:cherry_mvp/features/profile/profilepage.dart';
import 'package:cherry_mvp/features/home/widgets/dashboard.dart';
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
    DashboardPage(),
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
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: AppColors.primary,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
              icon: Image(
                image: AssetImage(AppImages.icHome),width: 24,height: 24,
              ),
              activeIcon: Image(
                image: AssetImage(AppImages.icHomeSelected),width: 24,height: 24,
              ), label: 'Home'
          ),
          BottomNavigationBarItem(
              icon: Icon(Icons.messenger_outline), label: 'Inbox'
          ),
          BottomNavigationBarItem(
              icon: Icon(Icons.private_connectivity_rounded), label: 'Search'
          ),
          BottomNavigationBarItem(
              icon: Icon(Icons.add), label: 'Add'
          ),
          BottomNavigationBarItem(
              icon: Icon(Icons.person), label: 'Profile'
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.black,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        onTap: _onItemTapped,
      ),
    );
  }
}

