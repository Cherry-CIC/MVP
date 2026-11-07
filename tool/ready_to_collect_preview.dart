// Local UI preview only. No authentication, API calls or real parcel actions.
import 'package:cherry_mvp/core/config/app_theme.dart';
import 'package:cherry_mvp/features/orders/collection_deadline.dart';
import 'package:cherry_mvp/features/orders/models/order_summary.dart';
import 'package:cherry_mvp/features/orders/widgets/ready_to_collect_dialog.dart';
import 'package:flutter/material.dart';

void main() => runApp(const ReadyToCollectPreview());

class ReadyToCollectPreview extends StatelessWidget {
  const ReadyToCollectPreview({super.key, this.expired = false, this.dark = false, this.fontFamily});
  final bool expired;
  final bool dark;
  final String? fontFamily;

  @override
  Widget build(BuildContext context) {
    final theme = buildTheme(dark ? Brightness.dark : Brightness.light);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: theme.copyWith(textTheme: theme.textTheme.apply(fontFamily: fontFamily)),
      home: _PreviewHome(expired: expired),
    );
  }
}

class _PreviewHome extends StatefulWidget {
  const _PreviewHome({required this.expired});
  final bool expired;

  @override
  State<_PreviewHome> createState() => _PreviewHomeState();
}

class _PreviewHomeState extends State<_PreviewHome> {
  late final DateTime _deadline;
  // Fixture data uses the existing bundled catalogue and charity assets.
  static const _order = OrderSummary(
    id: 'CH123456',
    productId: 'preview',
    productName: 'Example Product 2',
    imageUrl: 'assets/images/product1.png',
    size: 'L',
    condition: 'Barely worn',
    charityLogoUrl: 'assets/images/charity_home_start.png',
    itemPriceMinor: 800,
    totalAmountMinor: 880,
    currency: 'GBP',
    deliveryState: 'awaiting_collection',
    deliveryLabel: 'Ready to collect',
  );

  @override
  void initState() {
    super.initState();
    _deadline = collectionDeadlineFromArrival(
      DateTime.now().subtract(
        widget.expired ? const Duration(hours: 73) : const Duration(minutes: 1),
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _open());
  }

  Future<void> _open() async {
    final action = await showDialog<ReadyToCollectAction>(
      context: context,
      builder: (_) => ReadyToCollectDialog(
        order: _order,
        collectionDeadline: _deadline,
        canOpenMap: true,
        canTrackParcel: true,
      ),
    );
    if (!mounted || action == null || action == ReadyToCollectAction.dismiss) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          action == ReadyToCollectAction.openMap
              ? 'Preview: the app will open the parcel’s locker location.'
              : 'Preview: the app will open the parcel’s tracking page.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('cherry · collection preview')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          height: 145,
          decoration: BoxDecoration(color: const Color(0xFFF90653), borderRadius: BorderRadius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: Row(
            children: [
              const Expanded(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Explore\nCharities',
                        style: TextStyle(color: Colors.white, fontSize: 28, height: 1, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text('Discover something\nbeautiful here.', style: TextStyle(color: Colors.white, fontSize: 12)),
                    ],
                  ),
                ),
              ),
              Expanded(child: Image.asset('assets/images/explore_image.png', fit: BoxFit.cover, height: 145)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.68,
          children: [2, 3, 4, 1]
              .map(
                (i) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset('assets/images/product$i.png', width: double.infinity, fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(i == 4 ? 'Beige cargo shirt' : 'Pre-loved clothing'),
                    const Text('£8.00'),
                  ],
                ),
              )
              .toList(),
        ),
        FilledButton(onPressed: _open, child: const Text('Preview collection pop-up')),
      ],
    ),
    bottomNavigationBar: const BottomAppBar(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Icon(Icons.home_outlined),
          Icon(Icons.mail_outline),
          Icon(Icons.add),
          Icon(Icons.search),
          Icon(Icons.person_outline),
        ],
      ),
    ),
  );
}
