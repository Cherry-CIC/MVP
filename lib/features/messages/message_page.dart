import 'package:cherry_mvp/core/widgets/empty_state_card.dart';
import 'package:flutter/material.dart';
import 'package:cherry_mvp/core/config/config.dart';

class MessagePage extends StatelessWidget {
  const MessagePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.messages),
      ),
      body: Center(
        child: EmptyStateCard(message: AppStrings.emptyStateMessageText),
      ),
    );
  }
}
