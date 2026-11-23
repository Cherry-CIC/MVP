import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:cherry_mvp/core/config/feature_flags.dart';
import 'package:cherry_mvp/features/categories/category_view_model.dart';
import 'package:cherry_mvp/features/discover/discover_viewmodel.dart';
import 'package:cherry_mvp/features/discover/widgets/discover_categories_list.dart';
import 'package:cherry_mvp/features/discover/widgets/discover_charity_list.dart';
import 'package:cherry_mvp/features/discover/widgets/discover_selection_bar.dart';
import 'package:cherry_mvp/features/search/widgets/search.dart';

class DiscoverPage extends StatefulWidget {
  /// False when Discover is a footer tab, true when pushed as its own route.
  final bool showBackButton;

  const DiscoverPage({this.showBackButton = true, super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  String _selectedTag = DiscoverSelectionBar.popularTag;

  void _onTagSelected(String tag) {
    setState(() => _selectedTag = tag);
    if (tag == DiscoverSelectionBar.categoriesTag) {
      // Refresh on every visit so removed categories disappear.
      unawaited(context.read<CategoryViewModel>().fetchCategories());
    }
  }

  @override
  Widget build(BuildContext context) {
    final showingCategories = _selectedTag == DiscoverSelectionBar.categoriesTag;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      body: Consumer<DiscoverViewModel>(
        builder: (context, viewModel, _) {
          return SafeArea(
            bottom: false,
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  automaticallyImplyLeading: widget.showBackButton,
                  backgroundColor: backgroundColor,
                  surfaceTintColor: Colors.transparent,
                  scrolledUnderElevation: 0,
                  centerTitle: false,
                  titleSpacing: FeatureFlags.showSearch
                      ? (widget.showBackButton ? 0 : 16)
                      : NavigationToolbar.kMiddleSpacing,
                  title: FeatureFlags.showSearch
                      ? const Padding(
                          padding: EdgeInsets.only(right: 16),
                          child: Search(showAsBar: true),
                        )
                      : const Text('Discover'),
                  floating: true,
                  primary: false,
                  snap: true,
                ),
                if (FeatureFlags.showDiscoverSelectionBar)
                  SliverAppBar(
                    automaticallyImplyLeading: false,
                    backgroundColor: backgroundColor,
                    surfaceTintColor: Colors.transparent,
                    scrolledUnderElevation: 0,
                    title: DiscoverSelectionBar(
                      selectedTag: _selectedTag,
                      onSelected: _onTagSelected,
                    ),
                    primary: false,
                    pinned: true,
                  ),
                if (showingCategories)
                  DiscoverCategoriesList(
                    onCategorySelected: (category) => openSearch(context, initialCategory: category),
                  )
                else
                  SliverPadding(
                    padding: EdgeInsets.only(
                      top: FeatureFlags.showDiscoverSelectionBar ? 0 : 16,
                    ),
                    sliver: DiscoverCharityList(
                      charities: viewModel.fetchCharities(tag: _selectedTag),
                      products: viewModel.fetchProducts(),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
