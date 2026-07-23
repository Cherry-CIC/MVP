import 'package:flutter/material.dart';
import 'package:cherry_mvp/core/config/feature_flags.dart';
import 'package:cherry_mvp/features/home/home_viewmodel.dart';
import 'package:cherry_mvp/features/home/widgets/dashboard.dart';
import 'package:cherry_mvp/features/home/widgets/discover_button.dart';
import 'package:cherry_mvp/features/search/widgets/search.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final topSafeArea = MediaQuery.paddingOf(context).top;
    final discoverTopPadding = FeatureFlags.showSearch ? 16.0 : 16.0 + topSafeArea;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => context.read<HomeViewModel>().refreshProducts(),
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification.metrics.extentAfter < 600) {
              context.read<HomeViewModel>().loadMoreProducts();
            }
            return false;
          },
          child: CustomScrollView(
            slivers: [
              if (FeatureFlags.showSearch)
                PinnedHeaderSliver(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      8 + MediaQuery.of(context).padding.top,
                      16,
                      8,
                    ),
                    child: const Search(showAsBar: true),
                  ),
                ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(16, discoverTopPadding, 16, 16),
                sliver: const SliverToBoxAdapter(child: DiscoverButton()),
              ),
              const DashboardPage(),
            ],
          ),
        ),
      ),
    );
  }
}
