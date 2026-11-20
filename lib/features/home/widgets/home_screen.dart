import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cherry_mvp/core/config/feature_flags.dart';
import 'package:cherry_mvp/core/models/category.dart';
import 'package:cherry_mvp/features/categories/category_view_model.dart';
import 'package:cherry_mvp/features/home/home_viewmodel.dart';
import 'package:cherry_mvp/features/home/widgets/dashboard.dart';
import 'package:cherry_mvp/features/home/widgets/discover_button.dart';
import 'package:cherry_mvp/features/search/widgets/search.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  /// Opens the Discover footer tab; falls back to the Discover route when null.
  final VoidCallback? onOpenDiscover;

  const HomeScreen({this.onOpenDiscover, super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final categoryViewModel = context.read<CategoryViewModel?>();
      if (categoryViewModel != null) {
        unawaited(categoryViewModel.ensureCategoriesLoaded());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final topSafeArea = MediaQuery.paddingOf(context).top;
    final discoverTopPadding = FeatureFlags.showSearch ? 8.0 : 16.0 + topSafeArea;
    final categories = context.watch<CategoryViewModel?>()?.categories ?? const <Category>[];
    final selectedCategory = context.select<HomeViewModel, Category?>((vm) => vm.homeCategory);
    final showCategoryPills = FeatureFlags.showSearch && categories.isNotEmpty;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => context.read<HomeViewModel>().refreshProducts(),
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification.depth == 0 &&
                notification.metrics.axis == Axis.vertical &&
                notification.metrics.extentAfter < 600) {
              context.read<HomeViewModel>().loadMoreProducts();
            }
            return false;
          },
          child: CustomScrollView(
            slivers: [
              if (FeatureFlags.showSearch)
                SliverFloatingHeader(
                  child: ColoredBox(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            16,
                            4 + topSafeArea,
                            16,
                            showCategoryPills ? 8 : 6,
                          ),
                          child: const Search(showAsBar: true),
                        ),
                        if (showCategoryPills)
                          _HomeCategoryBar(
                            categories: categories,
                            selectedCategory: selectedCategory,
                            onSelected: (category) =>
                                context.read<HomeViewModel>().selectHomeCategory(category),
                          ),
                      ],
                    ),
                  ),
                ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(16, discoverTopPadding, 16, 16),
                sliver: SliverToBoxAdapter(
                  child: DiscoverButton(onTap: widget.onOpenDiscover),
                ),
              ),
              const DashboardPage(),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeCategoryBar extends StatelessWidget {
  const _HomeCategoryBar({
    required this.categories,
    required this.selectedCategory,
    required this.onSelected,
  });

  final List<Category> categories;
  final Category? selectedCategory;
  final ValueChanged<Category?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          _CategoryPill(
            label: 'All',
            isSelected: selectedCategory == null,
            onTap: () => onSelected(null),
          ),
          for (final category in categories) ...[
            const SizedBox(width: 8),
            _CategoryPill(
              label: category.name,
              isSelected: selectedCategory?.id == category.id,
              onTap: () => onSelected(category),
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colours = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: Material(
        color: isSelected
            ? colours.primary.withValues(alpha: 0.14)
            : colours.surfaceContainerHighest,
        shape: StadiumBorder(
          side: BorderSide(
            color: isSelected ? colours.primary : colours.outlineVariant,
          ),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Text(
              label,
              maxLines: 1,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: isSelected ? colours.primary : colours.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
