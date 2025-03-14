import 'package:flutter/material.dart';
import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/data/dummy_categories.dart';
import 'package:cherry_mvp/features/home/widgets/category.dart';

class DashboardAppBar extends StatelessWidget implements PreferredSizeWidget {
  @override
  final Size preferredSize;

  DashboardAppBar(Text text, {Key? key})
      : preferredSize = Size.fromHeight(60.0),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text('Dashboard'),
      actions: <Widget>[
        IconButton(
          icon: Icon(Icons.notifications),
          onPressed: () {
            // Handle notification icon press
          },
        ),
        IconButton(
          icon: Icon(Icons.settings),
          onPressed: () {
            // Handle settings icon press
          },
        ),
      ],
    );
  }
}