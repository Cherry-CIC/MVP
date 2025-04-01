import 'package:flutter/material.dart';
 
import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/features/home/widgets/recentlyViewed/recently_viewed_list.dart';
 

class RecentlyViewedListBottom extends StatefulWidget {
  const RecentlyViewedListBottom({super.key});

  
  @override
  State<RecentlyViewedListBottom> createState() => RecentlyViewedListBottomState();
}

class RecentlyViewedListBottomState extends State<RecentlyViewedListBottom> { 

  int _selectedIndex = 0;
  static const TextStyle optionStyle = TextStyle(fontSize: 30, fontWeight: FontWeight.bold);
  // static const List<Widget> _widgetOptions = <Widget>[
  final List<Widget> _widgetOptions = <Widget>[
    // Text('Index 0: Home', style: optionStyle),
    RecentlyViewedList(),
    Text('Index 1: Message', style: optionStyle),
    Text('Index 2: Search', style: optionStyle),
    Text('Index 3: More', style: optionStyle),
    Text('Index 4: Profile', style: optionStyle),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(title: const Text('BottomNavigationBar Sample')),
      body: Center(child: _widgetOptions.elementAt(_selectedIndex)),
      bottomNavigationBar: BottomNavigationBar( 
        items: const <BottomNavigationBarItem>[  
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
          BottomNavigationBarItem(
            // icon: Icon(Icons.email), label: ''
            icon: Badge(
              label: Text(''), 
              backgroundColor: Colors.green, 
              child: Icon(Icons.email), 
            ), 

            label: '', 
          ),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: ''  ),
        ],

        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.black,
        unselectedItemColor: AppColors.primary,
        iconSize: 35, 

        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}