import 'package:flutter/material.dart';
import 'package:cherry_mvp/core/reusablewidgets/emptystatecard.dart';
import 'package:cherry_mvp/core/config/config.dart';


class SearchPage extends StatelessWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppStrings.search,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.black,
          ),
          textAlign: TextAlign.center,
        ),
      ),
      body: EmptyStateCard(
        message: AppStrings.emptyStateSearchText,
      ),
    );
  }
}
