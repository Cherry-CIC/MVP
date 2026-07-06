import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/core/utils/utils.dart';
import 'package:cherry_mvp/features/categories/category_view_model.dart';
import 'package:cherry_mvp/features/categories/widget/category_empty_widget.dart';
import 'package:cherry_mvp/features/categories/widget/category_error_widget.dart';
import 'package:cherry_mvp/features/categories/widget/category_loading_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Search extends StatelessWidget {
  const Search({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CategoryViewModel>(
        builder: (context, categoryViewModel, _) {
      final status = categoryViewModel.status;
      final categories = categoryViewModel.categories;
      return SearchAnchor(
        searchController: context.read<SearchController>(),
        viewHintText: 'AI Search: Red Polka Dot Dress',
        viewBackgroundColor: Theme.of(context).colorScheme.surface,
        suggestionsBuilder: (context, controller) {
          if (status.type == StatusType.loading) {
            return [
              CategoryLoadingWidget(),
            ];
          } else if (status.type == StatusType.failure) {
            return [
              CategoryErrorWidget(
                errorMessage: status.message,
                onRetry: () => categoryViewModel.fetchCategories(),
              ),
            ];
          } else if (status.type == StatusType.success) {
            if (categories.isEmpty) {
              return [CategoryEmptyWidget()];
            }

            return categories.map((category) {
              return ListTile(
                onTap: () {},
                leading: Image.network(
                  category.imageUrl,
                  width: 32,
                  height: 32,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.broken_image,
                    color: AppColors.red,
                  ),
                ),
                title: Text(category.name),
                trailing: const Icon(Icons.chevron_right),
              );
            }).toList();
          }

          return [];
        },
        builder: (context, controller) => Image.asset(AppImages.icSearch,
            width: 24,
            height: 24,
            color: Theme.of(context).colorScheme.secondary),
      );
    });
  }
}
