import 'package:cherry_mvp/core/reusablewidgets/emptystatecard.dart';
import 'package:flutter/material.dart';
import 'package:cherry_mvp/core/config/config.dart';

class MessagePage extends StatelessWidget {
  const MessagePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppStrings.messages,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.black,
          ),
          textAlign: TextAlign.center,
        ),
      ),
      body: Center(
        child: EmptyStateCard(
          message: AppStrings.emptyStateMessageText
        ),
      ),
    );
  }
}