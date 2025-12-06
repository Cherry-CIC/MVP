import 'package:flutter/material.dart';
import '../../core/config/app_strings.dart';
import 'package:cherry_mvp/core/models/faqs_model.dart';
import 'package:cherry_mvp/features/settings/widgets/faq_category_tile.dart';

class FaqPage extends StatelessWidget {
  const FaqPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: Text(AppStrings.faqText),
            floating: true,
            snap: true,
          ),
          SliverList.builder(
            itemCount: dummyFaqData.length,
            itemBuilder: (context, index) {
              final category = dummyFaqData[index];
              return FaqCategoryTile(category: category);
            },
          ),
          SliverPadding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom + 16,
            ),
          ),
        ],
      ),
    );
  }
}

