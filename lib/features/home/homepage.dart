import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/features/home/widgets/bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomePage extends StatefulWidget {
  final Widget child;

  const HomePage({super.key, required this.child});

  @override
  HomePageState createState() {
    return HomePageState();
  }
}

class HomePageState extends State<HomePage> {
  var _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      body: widget.child,
      bottomNavigationBar: CherryBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemSelected: _onItemTapped,
        selectedColor: AppColors.primary,
        unselectedColor: AppColors.greyNavFooter,
      ),
    );
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        context.replace('/');
        break;
      case 1:
        context.replace('/search');
        break;
      case 2:
        context.replace('/add-product');
        break;
      case 3:
        context.replace('/messages');
        break;
      case 4:
        context.replace('/profile');
        break;
    }
  }
}
