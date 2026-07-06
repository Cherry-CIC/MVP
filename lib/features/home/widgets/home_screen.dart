import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cherry_mvp/core/config/feature_flags.dart';
import 'package:cherry_mvp/features/home/widgets/dashboard.dart';
import 'package:cherry_mvp/features/home/widgets/discover_button.dart';

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
      body: CustomScrollView(
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
                child: Material(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  elevation: 1,
                  shape: const StadiumBorder(),
                  child: InkWell(
                    onTap: context.read<SearchController>().openView,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search,
                            size: 16,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'AI Search: Red Polka Dot Dress',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(16, discoverTopPadding, 16, 16),
            sliver: const SliverToBoxAdapter(child: DiscoverButton()),
          ),
          const DashboardPage(),
        ],
      ),
    );
  }
}
