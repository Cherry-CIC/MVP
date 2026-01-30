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
    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      child: Consumer<HomeViewModel>(
        builder: (context, homeViewModel, _) {
          final navigator = Provider.of<NavigationProvider>(
            context,
            listen: false,
          );
          final productViewModel = Provider.of<ProductViewModel>(
            context,
            listen: false,
          );
          final products = homeViewModel.products;
          final status = homeViewModel.status;

          return Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),

                // Show loading widget when fetching data
                if (status.type == StatusType.loading)
                  const DashboardLoadingWidget()
                // Show error widget if failed
                else if (status.type == StatusType.failure)
                  DashboardErrorWidget(
                    errorMessage: status.message,
                    onRetry: () => homeViewModel.fetchProducts(),
                  )
                // Show products grid when data is loaded
                else if (products.isNotEmpty)
                  Builder(
                    builder: (context) {
                      const int adFrequency = 6;

                      final int productCount = products.length;
                      final int adCount = productCount ~/ adFrequency;
                      final int totalCount = productCount + adCount;

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: totalCount,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 6,
                          childAspectRatio: 0.6,
                        ),
                        itemBuilder: (context, index) {
                          final bool isAdPosition = productCount >= adFrequency &&
                              (index + 1) % (adFrequency + 1) == 0;

                          if (isAdPosition) {
                            return const AdExample();
                          }

                          final int adsBefore =
                              (index + 1) ~/ (adFrequency + 1);
                          final int productIndex = index - adsBefore;

                          if (productIndex < 0 || productIndex >= productCount) {
                            return const SizedBox.shrink();
                          }

                          final product = products[productIndex];

                          return GestureDetector(
                            onTap: () {
                              productViewModel.setProduct(product);
                              navigator.navigateTo(AppRoutes.product);
                            },
                            child: ProductCard(product: product),
                          );
                        },
                      );
                    },
                  )
                // Show empty state if no products
                else
                  const DashboardEmptyWidget(),
              ],
            ),
          );
        },
      ),
    );
  }
}
