import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
                elevation: 1,
                shape: const StadiumBorder(),
                child: InkWell(
                  onTap: context.read<SearchController>().openView,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
          const SliverPadding(
            padding: EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(child: DiscoverButton()),
          ),
          const DashboardPage(),
        ],
      ),
    );
  }
}
