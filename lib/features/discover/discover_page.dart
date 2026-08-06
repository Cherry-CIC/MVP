import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:cherry_mvp/core/config/feature_flags.dart';
import 'package:cherry_mvp/features/discover/discover_viewmodel.dart';
import 'package:cherry_mvp/features/discover/widgets/discover_charity_list.dart';
import 'package:cherry_mvp/features/discover/widgets/discover_selection_bar.dart';

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  String _selectedTag = 'popular';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<DiscoverViewModel>(
        builder: (context, viewModel, _) {
          final charities = viewModel.fetchCharities(tag: _selectedTag);
          final products = viewModel.fetchProducts();

          return SafeArea(
            bottom: false,
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  title: Text('Discover'),
                  floating: true,
                  primary: false,
                  snap: true,
                ),
                if (FeatureFlags.showDiscoverSelectionBar)
                  SliverAppBar(
                    automaticallyImplyLeading: false,
                    title: DiscoverSelectionBar(
                      selectedTag: _selectedTag,
                      onSelected: (tag) => setState(() => _selectedTag = tag),
                    ),
                    primary: false,
                    pinned: true,
                  ),
                SliverPadding(
                  padding: EdgeInsets.only(
                    top: FeatureFlags.showDiscoverSelectionBar ? 0 : 16,
                  ),
                  sliver: DiscoverCharityList(
                    charities: charities,
                    products: products,
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
