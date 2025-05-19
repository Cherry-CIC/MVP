import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/core/utils/utils.dart';
import 'package:cherry_mvp/features/search/search_viewmodel.dart';

import 'category.dart';

class CharityPage extends StatefulWidget {
  const CharityPage({super.key});

  @override
  CharityPageState createState() => CharityPageState();
}

class CharityPageState extends State<CharityPage> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Consumer<SearchViewModel>(builder: (context, viewModel, child) {
      final charities = viewModel.fetchCharityCategories();

      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(
              Icons.reply,
              color: AppColors.primary,
              size: 20,
            ),
            onPressed: () {},
          ),
          title: Padding(
              padding: EdgeInsets.only(left: 10.0, top: 5.0),
              child: Text(
                AppStrings.charitiesText,
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.black,
                  fontWeight: FontWeight.w700,
                ),
              )),
          centerTitle: true,
          actions: [],
        ),
        body: Container(
            padding: EdgeInsets.only(top: 5),
            child: Column(children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    decoration: buildInputDecorationSearch(
                        labelText: "Search items",
                        hintText: "",
                        iconPrefix: Icons.search,
                        icon: Icons.camera_alt_rounded,
                        enabledBorderRadiusValue: 50.0,
                        iconColor: AppColors.greyTextColor),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
              ),
              Padding(padding: EdgeInsets.only(top: 8)),
              Expanded(
                child: ListView.builder(
                  itemCount: charities.length,
                  itemBuilder: (context, index) {
                    return SingleCategory(charityCategory: charities[index]);
                  },
                ),
              ),
            ])),
      );
    });
  }
}
