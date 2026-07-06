import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:cherry_mvp/features/discover/discover_viewmodel.dart';
import 'package:cherry_mvp/features/discover/widgets/discover_charity_list.dart';
import 'package:cherry_mvp/features/discover/widgets/discover_selection_bar.dart';

class DiscoverPage extends StatelessWidget {
  const DiscoverPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<DiscoverViewModel>(
        builder: (context, viewModel, _) {
          final charities = viewModel.fetchCharities();
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
                SliverAppBar(
                  automaticallyImplyLeading: false,
                  title: const DiscoverSelectionBar(),
                  primary: false,
                  pinned: true,
                ),
                DiscoverCharityList(
                  charities: charities,
                  products: products,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
