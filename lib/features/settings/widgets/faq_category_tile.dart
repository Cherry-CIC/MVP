import 'package:cherry_mvp/core/models/faqs_model.dart';
import 'package:flutter/material.dart';

class FaqCategoryTile extends StatelessWidget {
  final FaqCategory category;

  const FaqCategoryTile({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: ExpansionTile(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        collapsedBackgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text(
          category.title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18),
        ),
        children: category.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              bottom: 8.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Question
                Text(
                  entry.question,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontSize: 15,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                // Answer
                Text(
                  entry.answer,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.justify,
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
