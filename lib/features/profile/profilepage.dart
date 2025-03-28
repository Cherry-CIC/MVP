import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Profile')),
      body: Center(
        child: Text(
          'Profile Content Here',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }
}