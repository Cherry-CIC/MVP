import 'package:cherry_mvp/core/router/nav_provider.dart';
import 'package:cherry_mvp/core/router/nav_routes.dart';
import 'package:cherry_mvp/features/categories/category_view_model.dart';
import 'package:cherry_mvp/features/home/widgets/ad_example.dart';
import 'package:cherry_mvp/features/products/product_card.dart';
import 'package:cherry_mvp/features/products/product_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cherry_mvp/features/home/home_viewmodel.dart';
import 'package:cherry_mvp/features/home/widgets/dashboard_loading_widget.dart';
import 'package:cherry_mvp/features/home/widgets/dashboard_error_widget.dart';
import 'package:cherry_mvp/features/home/widgets/dashboard_empty_widget.dart';
import 'package:cherry_mvp/core/utils/utils.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _hasInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_hasInitialized) {
      _hasInitialized = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        final categoryVM = context.read<CategoryViewModel>();
        final homeVM = context.read<HomeViewModel>();

        categoryVM.fetchCategories();
        homeVM.fetchProducts();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeViewModel>(
      builder: (context, homeViewModel, _) {
        final navigator = Provider.of<NavigationProvider>(context, listen: false);
        final productViewModel = Provider.of<ProductViewModel>(context, listen: false);
        final products = homeViewModel.products;
        final status = homeViewModel.status;

        if (status.type == StatusType.loading) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: DashboardLoadingWidget(),
          );
        }

        if (status.type == StatusType.failure) {
          return Padding(
            padding: const EdgeInsets.all(12),
            child: DashboardErrorWidget(
              errorMessage: status.message,
              onRetry: () => homeViewModel.fetchProducts(),
            ),
          );
        }

        if (products.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: DashboardEmptyWidget(),
          );
        }

        const int chunkSize = 6;
        List<Widget> children = [];

        for (var i = 0; i < products.length; i += chunkSize) {
          final end = (i + chunkSize < products.length) ? i + chunkSize : products.length;
          final productChunk = products.sublist(i, end);

          children.add(
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: productChunk.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.6,
                ),
                itemBuilder: (context, index) {
                  final product = productChunk[index];
                  return GestureDetector(
                    onTap: () {
                      productViewModel.setProduct(product);
                      navigator.navigateTo(AppRoutes.product);
                    },
                    child: ProductCard(product: product),
                  );
                },
              ),
            ),
          );

          // Show the ad if we have completed a full chunk of 6
          if (productChunk.length == chunkSize) {
            children.add(
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: AdExample(),
              ),
            );
          }
        }

        return Column(children: children);
      },
    );
  }
}
