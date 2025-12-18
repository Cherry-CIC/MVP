import 'package:cherry_mvp/core/utils/utils.dart';
import 'package:cherry_mvp/features/categories/category_view_model.dart';
import 'package:cherry_mvp/features/categories/widget/category_empty_widget.dart';
import 'package:cherry_mvp/features/categories/widget/category_error_widget.dart';
import 'package:cherry_mvp/features/search/widgets/category_tile_widget.dart';
import 'package:flutter/material.dart';
import 'package:cherry_mvp/core/config/app_images.dart';
import 'package:cherry_mvp/core/config/config.dart';
import 'package:provider/provider.dart';

import 'package:cherry_mvp/core/models/category.dart';

class CategoryPage extends StatefulWidget {
  const CategoryPage({
    super.key,
    this.selectionMode = false,
    this.initialCategoryId,
  });

  final bool selectionMode;
  final String? initialCategoryId;

  @override
  CategoryPageState createState() => CategoryPageState();
}

class CategoryPageState extends State<CategoryPage> {
  bool _hasInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitialized) {
      _hasInitialized = true;
      final categoryViewModel = Provider.of<CategoryViewModel>(
        context,
        listen: false,
      );
      if (categoryViewModel.categories.isEmpty) {
        categoryViewModel.fetchCategories();
      }
    }
  }

  void _handleCategoryTap(Category category) {
    if (widget.selectionMode) {
      Navigator.of(context).pop(category);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: InkWell(
          onTap: () => Navigator.of(context).maybePop(),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Image.asset(AppImages.backIcon, width: 24, height: 24),
          ),
        ),
        title: const Text(
          AppStrings.categoriesText,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 8.0, right: 15.0, left: 15.0),
        child: Consumer<CategoryViewModel>(
          builder: (context, categoryViewModel, _) {
            final status = categoryViewModel.status;
            final categories = categoryViewModel.categories;

            if (status.type == StatusType.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (status.type == StatusType.failure) {
              return CategoryErrorWidget(
                errorMessage: status.message,
                onRetry: () => categoryViewModel.fetchCategories(),
              );
            }

            if (categories.isEmpty) {
              return CategoryEmptyWidget();
            }

            return ListView.separated(
              itemBuilder: (BuildContext context, int index) {
                final category = categories[index];
                final isSelected =
                    widget.initialCategoryId != null &&
                    category.id == widget.initialCategoryId;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: CategoryTileWidget(
                    onTap: () => _handleCategoryTap(category),
                    image: category.imageUrl,
                    text: category.name,
                    icon: categoryViewModel.getCategoryIcon(category.name),
                    assetIcon: categoryViewModel.getCategoryAssetIcon(
                      category.name,
                    ),
                    trailing: widget.selectionMode && isSelected
                        ? Icon(
                            Icons.check_circle,
                            color: Theme.of(context).colorScheme.primary,
                          )
                        : null,
                  ),
                );
              },
              separatorBuilder: (BuildContext context, int index) {
                return const Divider();
              },
              itemCount: categories.length,
            );
          },
        ),
      ),
    );
  }
}
