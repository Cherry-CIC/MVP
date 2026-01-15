import 'package:flutter/material.dart';
import 'package:cherry_mvp/features/home/widgets/ad_example.dart';
import 'package:cherry_mvp/features/home/widgets/dashboard.dart';
import 'package:cherry_mvp/features/home/widgets/discover_button.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
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
                clipBehavior: Clip.antiAlias,
                elevation: 1,
                shape: StadiumBorder(),
                child: InkWell(
                  onTap: context.read<SearchController>().openView,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      spacing: 8,
                      children: [
                        Icon(
                          Icons.search,
                          size: 16,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        Text(
                          'AI Search: Red Polka Dot Dress',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.secondary,
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
            padding: EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(child: DiscoverButton()),
          ),
          SliverToBoxAdapter(child: AdExample()),
          SliverPadding(
            padding: EdgeInsets.zero,
            sliver: SliverToBoxAdapter(child: DashboardPage()),
          ),
        ],
      ),
    );
  }
}
