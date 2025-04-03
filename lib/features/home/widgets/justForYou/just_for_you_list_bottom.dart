import 'package:flutter/material.dart';
 
import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/features/home/widgets/justForYou/just_for_you_list.dart';
 

class JustForYouListBottom extends StatefulWidget {
  const JustForYouListBottom({super.key});

   
  @override
  State<JustForYouListBottom> createState() => JustForYouListBottomState();
}

class JustForYouListBottomState extends State<JustForYouListBottom> { 

  int _selectedIndex = 0;
  static const TextStyle optionStyle = TextStyle(fontSize: 30, fontWeight: FontWeight.bold); 
  final List<Widget> _widgetOptions = <Widget>[ 
    JustForYouList(),
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
              backgroundColor: AppColors.greenBgColor, 
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