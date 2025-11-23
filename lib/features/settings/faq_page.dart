import 'package:cherry_mvp/core/models/faqs_model.dart';
import 'package:flutter/material.dart';
import '../../core/config/app_strings.dart';

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
            itemCount:  dummyFaqData.length,
            itemBuilder: (context, index) {
              final product = basket.basketItems[index];
              return BasketListItem(
                product: product,
                onRemove: () => basket.removeItem(product),
              );
            },
          ),
         SliverList(delegate: delegate)
         dummyFaqData.map((category) {
              return FaqCategoryTile(category: category);
            }).toList(),

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

class FaqCategoryTile extends StatelessWidget {
  final FaqCategory category;

  const FaqCategoryTile({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: ExpansionTile(
        // Category title as the header
        title: Text(
          category.title,
          style: Theme.of(context).textTheme.titleMedium!.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        // Grouped questions as the collapsible content
        children: category.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Question
                Text(
                  entry.question,
                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                // Answer
                Text(
                  entry.answer,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const Divider(height: 20),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}