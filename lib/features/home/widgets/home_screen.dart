import 'package:cherry_mvp/features/home/widgets/ad_example.dart';
import 'package:cherry_mvp/features/home/widgets/dashboard.dart';
import 'package:flutter/material.dart';
import 'package:cherry_mvp/features/home/widgets/discover_button.dart';
import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/core/utils/utils.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: SizedBox(
          height: 40,
          child: TextField(
            decoration: buildInputDecorationSearchHome(
              labelText: "AI Search: Red Polka Dot Dress",
              hintText: "",
              iconPrefix: Icons.search,
              icon: null,
              enabledBorderRadiusValue: 50.0,
              iconColor: AppColors.greyTextColor,
            ),
            onChanged: (value) {
              setState(() {});
            },
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14),
          child: Column(
            children: [
              DiscoverButton(),
              AdExample(),
              DashboardPage(),
            ],
          ),
        ),
      ),
    );
  }
}
